require 'uri'

class PerspectivesController < ApplicationController
  include ApplicationHelper

  MAX_RADIUS = 5000

  before_filter :login_required, :except => [:index, :show, :nearby, :all]

  def new
    @place = Place.forgiving_find(params[:place_id])
    @perspective= current_user.perspective_for_place(@place)

    if @perspective.nil?
      track! :placemark
      @perspective= @place.perspectives.build()
      @perspective.client_application = current_client_application unless current_client_application.nil?
      @perspective.user = current_user
      @perspective.location = @place.location
    end

    @perspective.save!
    ActivityFeed.add_new_perspective(@perspective.user, @perspective, false)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def admin_create
    @perspective = Perspective.new(params[:perspective])

    @place = Place.forgiving_find(params['place_id'])
    if !@place.nil?
      if params[:username] and admin_user?
        @user = User.find_by_username(params[:username])
        if @user.nil?
          @perspective.errors.add(:user, "Invalid user")
        end
      else
        @user = current_user
      end
    else
      @perspective.errors.add(:place, "Invalid place")
    end

    if !@place.nil? and !@user.nil?
      @perspective.place = @place
      @perspective.user = @user

      @exists = Perspective.where(:uid => @user.id).and(:plid => @place.id)

      if @exists.length > 0
        @perspective.errors[:base] << "User already has a perspective for here"
      end

      if @perspective.errors.length > 0
        render :action => "new"
      else
        @perspective.pictures.each do |picture|
          picture.save
        end


        if @perspective.save
          respond_to do |format|
            format.html { redirect_to place_path(@place) }
          end
        else
          render :action => "new"
        end
      end
    else
      render :action => "new"
    end
  end

  def following
    @place = Place.forgiving_find(params['place_id'])

    @perspectives = []
    perspectives_count = 0
    if !@place.nil?
      @following_perspectives = current_user.following_perspectives_for_place(@place)

      @following_perspectives.each do |perspective|
        unless perspective.user.blocked?(current_user)
          perspectives_count += 1
          @perspectives << perspective unless perspective.empty_perspective?

          for perspective_id in perspective.favourite_perspective_ids
            hearted_perspective = Perspective.find(perspective_id)
            found = false
            for existing_perspective in @perspectives
              if existing_perspective.id == hearted_perspective.id
                found = true
              end
            end
            if found
              existing_perspective.liking_users << perspective.user.username
            else
              hearted_perspective.liking_users = [perspective.user.username]
              @perspectives << hearted_perspective
            end
          end

        end
      end
    end

    respond_to do |format|
      format.json { render :json => {:perspectives => @perspectives.as_json({:current_user => current_user, :place_view => true}), :count => perspectives_count} }
    end

  end

  def show
    #returns the place page (or json) for perspectives' host
    if !BSON::ObjectId.legal?(params[:id])
      raise ActionController::RoutingError.new('Not Found')
    end

    @perspective = Perspective.find(params[:id])
    not_found unless !@perspective.nil?
    @place = @perspective.place

    @referring_user = @perspective.user

    if !params[:api_call]
      @nearby = []

      related = Perspective.where(:ploc => {"$near" => @perspective.ploc}, :uid => @perspective.user.id)

      counter = 0
      related.each do |perp|
        if perp != @perspective && !perp.empty_perspective? && haversine_distance(@perspective.ploc[0], @perspective.ploc[1], perp.ploc[0], perp.ploc[1])['m'] < MAX_RADIUS
          @nearby << perp
          counter += 1
          if counter > 2
            break
          end
        end
      end
    end

    respond_to do |format|
      format.html
      format.json { render :json => @place.as_json({:detail_view => true, :current_user => current_user, :referring_user => @referring_user}) }
    end
  end


  def all
    @place = Place.forgiving_find(params['place_id'])

    @perspectives = []
    if !@place.nil?
      @all_perspectives = @place.perspectives
      perspectives_count = @all_perspectives.count
      for perspective in @all_perspectives
        @perspectives << perspective unless perspective.empty_perspective?
      end
    end

    respond_to do |format|
      format.json { render :json => {:perspectives => @perspectives.as_json({:current_user => current_user, :place_view => true}), :count => perspectives_count} }
    end
  end

  def flag
    @perspective = Perspective.find(params[:id])

    @perspective.flagme(current_user)

    @perspective.save

    respond_to do |format|
      format.js
      format.json { render :json => {:result => "flagged"} }
    end
  end

  def star
    @perspective = Perspective.find(params[:id])

    @user_perspective = current_user.star(@perspective)

    track! :star
    ActivityFeed.add_star_perspective(current_user, @perspective.user, @perspective)

    # Need following for place page html: need to show blank perspective for current user
    if request.referer && URI(request.referer).path == place_path(@perspective.place)
      @my_perspective = Perspective.where('uid' => current_user._id, 'plid' => @perspective.place._id)[0]
    end

    respond_to do |format|
      format.js
      format.json { render :json => {:result => "starred", :perspective => @user_perspective.as_json({:current_user => current_user, :detail_view => true})} }
    end
  end

  def unstar
    @perspective = Perspective.find(params[:id])
    current_user.unstar(@perspective)

    respond_to do |format|
      format.js
      format.json { render :json => {:result => "unstarred"} }
    end
  end

  def index
    @user = User.find_by_username(params[:user_id])
    start_pos = params[:start].to_i

    count = 20

    if (params[:lat] && params[:lng])
      span =1
      lat = params[:lat].to_f
      long = params[:lng].to_f
      location = [lat, long]

      @perspectives = Perspective.find_nearby_for_user(@user, location, span, start_pos, count).includes(:place)
    else
      @perspectives = Perspective.find_recent_for_user(@user, start_pos, count).includes(:place)
    end

    respond_to do |format|
      format.json { render :json => {:perspectives => @perspectives.as_json({:current_user => current_user, :user_view => true})}, :callback => params[:callback] }
    end
  end

  def edit
    @perspective = Perspective.find(params[:id])
    # handle case where user refreshes page from browser bar => no referer
    if request.referer != "/"
      session[:referring_url] = URI(request.referer).path unless request.referer.nil? # Strip params otherwise may get wrong result on user.show
    end
  end

  def update
    # if coming from mobile client, will have param 'place_id'
    # otherwise web client
    new_perspective = false
    if params['place_id'].nil?
      @perspective = Perspective.find(params[:id])

      if @perspective.user == current_user
        @perspective.update_attributes(params[:perspective])
        params[:fb_post] = true #default to send to OG for now

        if @perspective.url == ""
          @perspective.url = nil
          @perspective.save
        end

        if params[:perspective].has_key?(:pictures_attributes)
          params[:perspective][:pictures_attributes].each do |picture|
            if picture[1].has_key?("image")
              photo = Picture.new
              photo.image = picture[1][:image]
              if photo.valid?
                @perspective.pictures.concat([photo])
              end
            else
              if picture[1]["_destroy"] == "1"
                photo = @perspective.pictures[picture[0].to_i]
                photo.deleted = true
                photo.save
              end
            end
          end
          @perspective.save
        end
      end
    else
      #this can also function as a "create", given that a user can only have one perspective for a place
      @place = Place.forgiving_find(params['place_id'])

      @perspective= current_user.perspective_for_place(@place)

      if @perspective.nil?
        track! :placemark
        @perspective= @place.perspectives.build(params.slice("memo", "url"))
        @perspective.client_application = current_client_application unless current_client_application.nil?
        @perspective.user = current_user
        if (params[:lat] and params[:long])
          @perspective.location = [params[:lat].to_f, params[:long].to_f]
          @perspective.accuracy = params[:accuracy]
        else
          @perspective.location = @place.location #made raw, these are by definition the same
          @perspective.accuracy = params[:accuracy]
        end
        new_perspective = true
      end

      if current_client_application && current_client_application.id.to_s == "4f298a1057b4e33324000003"
        #is a pinta
        if @perspective[:pinta_flag].nil?
          @perspective[:pinta_flag]= true
          track! :wordpress_post
        end
        #pinta supercedes all for now, when it comes to tracking
        @perspective.client_application = current_client_application unless current_client_application.nil?
      end

      if params[:memo]
        @perspective.memo = params[:memo]
      end

      if params[:url]
        @perspective.url = params[:url]
      end
    end

    @perspective.notify_modified

    if @perspective.save
      @perspective.place.update_tags

      if params[:post_delay]
        @perspective.post_delay = params[:post_delay].to_i * 60
      end

      if new_perspective
        ActivityFeed.add_new_perspective(@perspective.user, @perspective, !params[:fb_post].nil?)
      else
        ActivityFeed.add_update_perspective(@perspective.user, @perspective, !params[:fb_post].nil?)
      end

      if params[:photo_urls] #has to be done after save in case perspective didn't exist
                             #we don't know how slow their server is, so do this async
        Resque.enqueue(GetPerspectivePicture, @perspective.id, params[:photo_urls].split(','))
      end

      @perspective.place.save
      respond_to do |format|
        format.html { redirect_to session[:referring_url] }
        format.json { render :json => @perspective.as_json({:current_user => current_user, :detail_view => true}) }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render :json => {:status => 'fail'} }
      end
    end

  end

  def destroy
    # if coming from mobile client, will have param 'place_id'
    # otherwise web client
    redirect_path = ""

    if params['place_id'].nil?
      @perspective = Perspective.find(params[:id])

      @place = @perspective.place

      # User can delete on web from Place Page, Perspective Page or User Page; need to redirect to correct one
      if URI(request.referer).path == place_path(@place)
        redirect_path = place_path(@place)
      elsif URI(request.referer).path == magazine_user_path(current_user)
        redirect_path = magazine_user_path(current_user)
      else
        redirect_path = user_path(current_user)
      end
    else
      @place = Place.forgiving_find(params['place_id'])

      @perspective= current_user.perspective_for_place(@place)
    end

    if !@perspective.nil? and @perspective.user == current_user
      all_perps = Perspective.where('plid' => @place._id)

      all_perps.each do |perp|
        if perp.su.include?(current_user._id)
          perp.su.delete(current_user._id)
          perp.save
        end
      end

      @perspective.destroy
      @place.save
    end

    respond_to do |format|
      format.html { redirect_to redirect_path }
      format.json { render :json => {:status => 'deleted'} }
    end
  end

  def nearby
    #doesn't actually return perspectives, just places for given perspectives
    lat = params[:lat].to_f
    long = params[:lng].to_f
    span = params[:span].to_f #needs to be > 0

    span = span * 2

    if long.nil? || long == 0
      long = params[:long].to_f
    end

    if params[:username]
      user = User.find_by_username(params[:username])
      @places = Place.nearby_for_user(user, lat, long, span)
    else
      #for finding *all* perspectives nearby
      @places = Place.all_near(lat, long, span)
    end

    respond_to do |format|
      format.html
      format.json { render :json => {:places => @places.as_json({:current_user => current_user})} }
    end

  end

end
