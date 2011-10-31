class PerspectivesController < ApplicationController
  before_filter :login_required, :except =>[:index, :show, :nearby, :all]

  def new
    @place = Place.find(params[:place_id])
    @perspective = Perspective.new
    @perspective.pictures.build
    
    respond_to do |format|
      format.html
    end
  end
  
  def admin_create
    @perspective = Perspective.new(params[:perspective])
    
    @place = Place.find( params['place_id'])
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
        @perspective.errors.add_to_base("User already has a perspective for here")
      end
      
      if @perspective.errors.length > 0
        render :action => "new"
      else
        @perspective.pictures.each do |picture|
          picture.save
        end
        
        
        if @perspective.save
          respond_to do |format|
            format.html {redirect_to place_path(@place)}
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
    if BSON::ObjectId.legal?( params['place_id'] )
      #it's a direct request for a place in our db
      @place = Place.find( params['place_id'])
    else
      @place = Place.find_by_google_id( params['place_id'] )
    end

    @perspectives = current_user.following_perspectives_for_place( @place )
    perspectives_count = @perspectives.count

    for perspective in @perspectives
      @perspectives.delete( perspective ) unless !perspective.empty_perspective?
    end

    respond_to do |format|
      format.json { render :json => {:perspectives =>@perspectives.as_json({:current_user => current_user, :place_view => true}), :count => perspectives_count} }
    end

  end

   def show
     #returns the place page (or json) for perspectives' host
    @perspective = Perspective.find( params[:id] )
    @place = @perspective.place

    @referring_user = @perspective.user

    respond_to do |format|
      format.html
      format.json { render :json => @place.as_json({:detail_view => true, :current_user => current_user, :referring_user =>@referring_user}) }
    end
  end

  def all
    if BSON::ObjectId.legal?( params['place_id'] )
      #it's a direct request for a place in our db
      @place = Place.find( params['place_id'])
    else
      @place = Place.find_by_google_id( params['place_id'] )
    end

    @perspectives = @place.perspectives
    perspectives_count = @perspectives.count

    for perspective in @perspectives
      @perspectives.delete( perspective ) unless !perspective.empty_perspective?
    end

    respond_to do |format|
      format.json { render :json => {:perspectives =>@perspectives.as_json({:current_user => current_user, :place_view => true}), :count => perspectives_count} }
    end
  end

  def flag
    @perspective = Perspective.find( params[:id] )

    @perspective.flagme( current_user)

    @perspective.save

    respond_to do |format|
      format.json { render :json =>{:result => "flagged"} }
    end
  end

  def star
    @perspective = Perspective.find( params[:id] )

    current_user.star( @perspective )

    current_user.save
    @perspective.save

    respond_to do |format|
      format.json { render :json =>{:result => "starred"} }
    end
  end

  def unstar
    @perspective = Perspective.find( params[:id] )
    current_user.unstar( @perspective )

    current_user.save
    @perspective.save

    respond_to do |format|
      format.json { render :json =>{:result => "unstarred"} }
    end
  end

  def index
    @user = User.find_by_username( params[:user_id] )
    start_pos = params[:start].to_i

    lat = params[:lat].to_f
    long = params[:lng].to_f

    count = 20
        if long.nil? || long == 0
      long = params[:long].to_f
    end

    if (lat && long)
      location = [lat, long]
    end

    @perspectives = Perspective.find_recent_for_user( @user, start_pos, count )

    respond_to do |format|
      format.json { render :json => {:perspectives => @perspectives.as_json( {:current_user => current_user, :user_view => true} ) }  }
      format.html
    end
  end

  def update
    #this can also function as a "create", given that a user can only have one perspective for a place
    if BSON::ObjectId.legal?( params['place_id'] )
      #it's a direct request for a place in our db
      @place = Place.find( params['place_id'])
    else
      @place = Place.find_by_google_id( params['place_id'] )
    end

    @perspective= current_user.perspective_for_place( @place )

    if @perspective.nil?
      @perspective= @place.perspectives.build(params.slice("memo"))
      @perspective.client_application = current_client_application unless current_client_application.nil?
      @perspective.user = current_user
      if (params[:lat] and params[:long])
          @perspective.location = [params[:lat].to_f, params[:long].to_f]
          @perspective.accuracy = params[:accuracy]
      else
        @perspective.location = @place.location #made raw, these are by definition the same
        @perspective.accuracy = params[:accuracy]
      end
    end

    if params[:memo]
      @perspective.update_attributes(params.slice("memo"))
    end

    if @perspective.save
      respond_to do |format|
        format.html
        format.json { render :json => @perspective.as_json({:current_user => current_user}) }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render :json => {:status => 'fail'} }
      end
    end

  end


  def destroy
    if BSON::ObjectId.legal?( params['place_id'] )
      #it's a direct request for a place in our db
      @place = Place.find( params['place_id'])
    else
      @place = Place.find_by_google_id( params['place_id'] )
    end

    @perspective= current_user.perspective_for_place( @place )

    if !@perspective.nil?
      @perspective.delete
    end

    respond_to do |format|
      format.html { render :index }
      format.json { render :json => {:status => 'deleted'} }
    end
  end

  def nearby
    #doesn't actually return perspectives, just places for given perspectives
    lat = params[:lat].to_f
    long = params[:lng].to_f
    span = params[:span].to_f #needs to be > 0

    if long.nil? || long == 0
      long = params[:long].to_f
    end

    if params[:username]
      user = User.find_by_username( params[:username] )
      @places = Place.find_nearby_for_user( user, lat, long, span )
    else
      #for finding *all* perspectives nearby
      @places = Place.find_all_near(lat, long, span)
    end

    respond_to do |format|
      format.html
      format.json { render :json => {:places => @places.as_json({:current_user => current_user})} }
    end

  end

end
