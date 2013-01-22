require 'json'
require 'google_reverse_geocode'

NEARBY_RADIUS = 0.0035
DEFAULT_LAT = 49.9
DEFAULT_LNG = -97.1
DEFAULT_ZOOM = 3
DEFAULT_EMBED_ZOOM = 15
DEFAULT_WIDTH = 280
DEFAULT_HEIGHT = 200
PREVIEW_IFRAME_WIDTH = 400
PREVIEW_IFRAME_HEIGHT = 500

MAX_POPULAR = 20
DEFAULT_USER_ZOOM = 14

class UsersController < ApplicationController
  include ApplicationHelper

  before_filter :login_required, :only => [:me, :update, :follow, :unfollow, :add_facebook, :update, :account, :download, :block, :unblock, :pic, :update_pic, :location, :update_location, :notifications]
  before_filter :download_app, :only => [:show]

  def me
    @user = current_user

    #this is the final step in routes, if this doesn't work its a 404 -iMack
    raise ActionController::RoutingError.new('Not Found') unless !@user.nil?

    #for map view on web, get current page state
    if params[:api_call].nil?
      @current_location = []
      if !cookies[:page_state].nil?
        page_state = JSON.parse(cookies[:page_state])
        if page_state.has_key?(@user.username)
          @current_location << page_state[@user.username]['lat']
          @current_location << page_state[@user.username]['lng']
        end
      end

      @default_location = []
      if !@user.perspectives.nil? && @user.perspectives.length > 0
        @default_location << @user.perspectives[0].place_stub.loc[0]
        @default_location << @user.perspectives[0].place_stub.loc[1]
      else
        @default_location << 49.2
        @default_location << -123.2
      end
    end

    respond_to do |format|
      format.html { render :show }
      format.json { render :json => @user.as_json({:current_user => current_user, :perspectives => :created_by}) }
    end
  end

  def create
    return unless params[:format] == :json

    lat = params[:lat].to_f
    lng = params[:lng].to_f

    if lng.nil? or lng == 0
      lng = params[:long].to_f
    end

    if (params[:facebook_access_token])
      user = User.new(:username => params[:username].strip,
                      :email => params[:email], :password => Devise.friendly_token[0, 20])

      if user.valid?
        #these trigger an implicit save that seems to override validations
        user.confirm! #indicates that it doesn't need a confirmation, since we got email from Facebook
        auth = user.authentications.build(:expiry => params[:facebook_expiry_date], :provider => "facebook", :uid => params[:facebook_id], :token => params[:facebook_access_token])
        #Notifier.welcome(user.id).deliver!
      end
    else
      user = User.new(:username => params[:username].strip,
                      :email => params[:email],
                      :password => params[:password],
                      :confirmation_password => params[:password])
    end

    if  lat != 0 && lng !=0
      user.location = [lat, lng]
    else
      loc = get_location
      if loc && loc["remote_ip"]
        user.location = [loc["remote_ip"]["lat"], loc["remote_ip"]["lng"]]
      end
    end

    if user.save
      auth.save! unless auth.nil?

      @mixpanel.track_event("Sign Up", {:username => user.username})

      if current_client_application
        #send back some access keys so user can immediately start
        request_token = current_client_application.create_request_token
        request_token.authorize!(user)
        request_token.provided_oauth_verifier = request_token.verifier
        access_token = request_token.exchange!

        user.first_run.dismiss_app_ad = true
        user.first_run.downloaded_app = true
        user.save

        respond_to do |format|
          format.json { render :json => {:status => "success", :token => access_token.to_query, :user => user.as_json({:current_user => current_user, :perspectives => :created_by})} }
        end
      else
        respond_to do |format|
          format.json { render :json => {:status => "success"} }
        end
      end
    else
      respond_to do |format|
        format.json { render :json => {:status => "fail", :message => user.errors} }
      end
    end
  end

  def add_facebook
    user = current_user
    user.facebook_access_token = params[:facebook_access_token]
    user.facebook_id = params[:facebook_id].to_i
    user.save
  end

  def search
    query = params[:q]

    @users = User.search_by_username(query)

    respond_to do |format|
      format.html
      format.json { render :json => {:status => "success", :users => @users.as_json({:current_user => current_user})} }
    end
  end

  def wimdu
    @user = User.find_by_username('lindsayrgwatt')
    @zoom = 13
    @lat = 52.50198
    @lng = 13.41770
    @width = 700
    @height = 488

    respond_to do |format|
      format.html { render :layout => 'blank' }
    end
  end

  def pinta
    @user = User.find_by_username(params[:id])
    @newwin = params['newwin'] =="1"

    if params['lat'].nil?
      @lat = @user.location[0]
    else
      @lat = params['lat'].to_f
      if @lat > 90 or @lat < -90
        @lat = @user.location[0]
      end
    end

    if params['lng'].nil?
      @lng = @user.location[1]
    else
      @lng = params['lng'].to_f
      if @lng > 180 or @lng < -180
        @lng = @user.location[1]
      end
    end

    @zoom = DEFAULT_ZOOM

    respond_to do |format|
      format.html { render :layout => nil }
    end
  end

  def iframe
    @user = User.find_by_username(params[:id])

    if params[:lat].nil?
      @lat = DEFAULT_LAT
    else
      @lat = params[:lat].to_f
      if @lat > 90 or @lat < -90
        @lat = DEFAULT_LAT
      end
    end

    if params[:lng].nil?
      @lng = DEFAULT_LNG
    else
      @lng = params[:lng].to_f
      if @lng > 180 or @lng < -180
        @lng = DEFAULT_LNG
      end
    end

    if params[:zoom].nil?
      @zoom = DEFAULT_ZOOM
    else
      @zoom = params[:zoom].to_i
      if @zoom > 20 or @zoom < 1
        @zoom = DEFAULT_ZOOM
      end
    end

    if params[:h].nil?
      @height = DEFAULT_HEIGHT
    else
      @height = params[:h].to_i
      if @height < 1
        @height = DEFAULT_HEIGHT
      end
    end

    if params[:w].nil?
      @width = DEFAULT_WIDTH
    else
      @width = params[:w].to_i
      if @width < 1
        @width = DEFAULT_WIDTH
      end
    end

    respond_to do |format|
      format.html { render :layout => 'blank' }
    end
  end

  def embed
    @user = User.find_by_username(params[:id])

    # Don't know how to change this based on environment, so storing here for now
    @url = CHATHAM_CONFIG['iframe_domain']

    # Need a current location and zoom for the map.
    @current_location = []
    if !@user.location.nil? && @user.location.length == 2
      @current_location = @user.location
    elsif !@user.perspectives.nil? && @user.perspectives.length > 0
      @current_location = @user.perspectives[0].place_stub.loc
    else
      @current_location << 49.2
      @current_location << -123.2
    end

    @zoom = DEFAULT_EMBED_ZOOM
    @height = PREVIEW_IFRAME_HEIGHT
    @width = PREVIEW_IFRAME_WIDTH

    respond_to do |format|
      format.html
    end
  end

  def show
    @user = User.find_by_username(params[:id])

    #this is the final step in routes, if this doesn't work its a 404 -iMack
    raise ActionController::RoutingError.new('Not Found') unless !@user.nil?

    #for map view on web, get current page state
    if params[:api_call].nil?
      # Use following logic to determine what lat/lng to show to viewer:
      # 1. If valid perspective passed in parameters, use that
      # 2. Else, if valid lat/lng in parameters, use that
      # 3. Else, if already have a lat/lng for @user, go there
      # 4. Else, if have viewer's lat/lng and @user has places near there, return location of first place near there that @user has
      # 5. Else, return first place on @user's map
      # 6. Else, return default lat/lng

      @current_location = []

      if !params[:pid].nil?
        persp = Perspective.where({'uid' => @user._id, '_id' => params[:pid]}).first

        if !persp.nil?
          @current_location = persp.place.loc
          # Need to update page_state cookie so that it will show the infowindow for current perspective
          if cookies[:page_state].nil?
            page_state = {@user.username => {'infowindow' => params[:pid], 'server' => true}}
          else
            page_state = JSON.parse(cookies[:page_state])

            if page_state.has_key?(@user.username)
              page_state[@user.username]['infowindow'] = params[:pid]
              page_state[@user.username]['server'] = true
            else
              page_state[@user.username] = {'infowindow' => params[:pid], 'server' => true}
            end
          end

          cookies[:page_state] = {:value => page_state.to_json}
        end
      end

      if @current_location.length == 0 && !params[:lat].nil? && !params[:lng].nil?
        lat = params[:lat].to_f
        lng = params[:lng].to_f

        if lat <= 90.0 && lat >= -90.0 && lng <= 180.0 && lng >= -180.0
          @current_location << lat
          @current_location << lng
        end
      end

      if @current_location.length == 0 && !cookies[:page_state].nil?
        page_state = JSON.parse(cookies[:page_state])
        if page_state.has_key?(@user.username) && page_state[@user.username].has_key?('lat') && page_state[@user.username].has_key?('lng')
          @current_location << page_state[@user.username]['lat']
          @current_location << page_state[@user.username]['lng']
        end
      end

      if @current_location.length == 0 && !@user.perspectives.nil? && @user.perspectives.length > 0
        # Won't have location cookie if visiting site for first time
        if cookies[:location].nil?
          location = get_location
        else
          location = JSON.parse(cookies[:location])
        end

        if location.has_key?("browser") or location.has_key?("remote_ip")
          if location.has_key?("browser")
            loc = [location["browser"]["lat"], location["browser"]["lng"]]
          else
            loc = [location["remote_ip"]["lat"], location["remote_ip"]["lng"]]
          end

          perps = Perspective.where(:ploc.within => {"$center" => [loc, 0.05]}, :uid => @user.id)

          if perps.length > 0
            @current_location = perps[0].ploc
          end
        end
      end

      if params[:zoom]
        @zoom = params[:zoom].to_i
        if @zoom > 20 or @zoom < 1
          @zoom = DEFAULT_ZOOM
        end
      end

      @default_location = []
      if !@user.perspectives.nil? && @user.perspectives.length > 0
        @default_location << @user.perspectives[0].place_stub.loc[0]
        @default_location << @user.perspectives[0].place_stub.loc[1]
      else
        @default_location << 49.2
        @default_location << -123.2
      end
    end

    respond_to do |format|
      format.html
      format.json { render :json => @user.as_json({:current_user => current_user, :perspectives => :created_by}) }
    end
  end

  def bounds
    @user = User.find_by_username(params[:id])

    @perspectives = []

    valid_params = true

    if params[:top_lat].nil? || params[:bottom_lat].nil? || params[:left_lng].nil? || params[:right_lng].nil?
      valid_params = false
    else
      top_lat = params[:top_lat].to_f
      if top_lat > 90 or top_lat < -90
        valid_params = false
      end

      if valid_params
        bottom_lat = params[:bottom_lat].to_f
        if bottom_lat > 90 or top_lat < -90 or bottom_lat > top_lat
          valid_params = false
        end

        if valid_params
          left_lng = params[:left_lng].to_f
          if left_lng < -180 || left_lng > 180
            valid_params = false
          end

          if valid_params
            right_lng = params[:right_lng].to_f
            if right_lng > 180 || right_lng < -180
              valid_params = false
            end
          end
        end
      end
      # Query fails if at exact edge, so reassign limits
      top_lat = [89.999999, top_lat].min
      bottom_lat = [-89.999999, bottom_lat].max
      right_lng = [right_lng, 179.999999].min
      right_lng = [right_lng, -179.999999].max
      left_lng = [left_lng, 179.999999].min
      left_lng = [left_lng, -179.999999].max

      # Edge case where user zooms so far out on map that multiple earths are visible
      if valid_params && right_lng < left_lng
        right_lng, left_lng = left_lng, right_lng
      end
    end

    if valid_params && top_lat != bottom_lat && right_lng != left_lng
      @perspectives = Perspective.where(:ploc.within => {"$box" => [[bottom_lat, left_lng], [top_lat, right_lng]]}, :uid => @user.id).includes(:place, :user)
    else
      @perspectives = []
    end

    respond_to do |format|
      format.json { render :json => {:perspectives => @perspectives.as_json({:user_view => true, :current_user => current_user, :bounds => true})} }
    end
  end

  def nearby
    @users = {}

    page_owner = User.find_by_username(params[:id])

    valid_params = true

    zoom = DEFAULT_USER_ZOOM

    if params[:top_lat].nil? || params[:bottom_lat].nil? || params[:left_lng].nil? || params[:right_lng].nil? || params[:center_lat].nil? || params[:center_lng].nil?
      valid_params = false
    else
      if params[:zoom]
        zoom = params[:zoom].to_i
        if zoom < 1 || zoom > 20 # Only 20 levels of Google zoom
          zoom = DEFAULT_USER_ZOOM
        end
      end

      center_lat = params[:center_lat].to_f
      if center_lat > 90 or center_lat < -90
        valid_params = false
      end

      top_lat = params[:top_lat].to_f
      if top_lat > 90 or top_lat < -90
        valid_params = false
      end

      if valid_params
        bottom_lat = params[:bottom_lat].to_f
        if bottom_lat > 90 or top_lat < -90 or bottom_lat > top_lat
          valid_params = false
        end

        if valid_params
          left_lng = params[:left_lng].to_f
          if left_lng < -180 || left_lng > 180
            valid_params = false
          end

          center_lng = params[:center_lng].to_f
          if center_lng < -180 || center_lng > 180
            valid_params = false
          end

          if valid_params
            right_lng = params[:right_lng].to_f
            if right_lng > 180 || right_lng < -180
              valid_params = false
            end
          end
        end
      end

      # Query fails if at exact edge, so reassign limits
      if valid_params
        top_lat = [89.999999, top_lat].min
        bottom_lat = [-89.999999, bottom_lat].max
        right_lng = [right_lng, 179.999999].min
        right_lng = [right_lng, -179.999999].max
        left_lng = [left_lng, 179.999999].min
        left_lng = [left_lng, -179.999999].max
      end

      # Edge case where user zooms so far out on map that multiple earths are visible
      if valid_params && right_lng < left_lng
        right_lng, left_lng = left_lng, right_lng
      end
    end

    if zoom < 12 # Somewhat arbitrarily chosen: corresponds to roughly Manhattan on a MacBook Pro 15" display
      @users["zoom"] = true
    else
      if valid_params && top_lat != bottom_lat && right_lng != left_lng
        location = {"lat" => center_lat, "lng" => center_lng, "zoom" => zoom}

        box = [[bottom_lat, left_lng], [top_lat, right_lng]]

        @users["owner"] = false

        questions = Question.nearby_questions(center_lat, center_lng)

        if questions.length > 0
          @users["questions"] = {}
          @users["questions"]["lat"] = center_lat
          @users["questions"]["lng"] = center_lng
          @users["questions"]["count"] = questions.length
        end

        if current_user
          following_counts = Perspective.collection.group(
              :cond => {:ploc => {'$within' => {'$box' => box}}, :uid => {"$in" => current_user.following_ids}, :deleted_at => {'$exists' => false}},
              :key => 'uid',
              :initial => {count: 0},
              :reduce => "function(obj,prev) {prev.count++}"
          )

          following_counts.sort! { |x, y| y["count"] <=> x["count"] }

          following = []

          @users["following"] = following

          following_counts.each do |person|
            member = User.find(person["uid"])
            following << {
                "name" => member.username.downcase,
                "pic" => member.thumb_url,
                "count" => person["count"].to_i,
                "url" => user_path(member)+"?"+location.to_query
            }
          end

          following.sort! { |x, y| [y["count"], x["name"]] <=> [x["count"], y["name"]] }

          popular_counts = Perspective.collection.group(
              :cond => {:ploc => {'$within' => {'$box' => box}}, :uid => {"$nin" => current_user.following_ids}, :deleted_at => {'$exists' => false}},
              :key => 'uid',
              :initial => {count: 0},
              :reduce => "function(obj,prev) {prev.count++}"
          )

          popular_counts.sort! { |x, y| y["count"] <=> x["count"] }

          if popular_counts.length > MAX_POPULAR + 1
            popular_counts = popular_counts[0, MAX_POPULAR + 1]
          end

          popular = []

          popular_counts.each do |person|
            member = User.find(person["uid"])
            if member != current_user && member != page_owner
              popular << {
                  "name" => member.username.downcase,
                  "pic" => member.thumb_url,
                  "count" => person["count"].to_i,
                  "url" => user_path(member)+"?"+location.to_query
              }
            end
            if member == page_owner
              @users['owner'] = true
            end
          end

          if popular.length > MAX_POPULAR
            popular = popular[0, MAX_POPULAR]
          end

          popular.sort! { |x, y| [y["count"], x["name"]] <=> [x["count"], y["name"]] }

          @users["popular"] = popular
        else
          popular_counts = Perspective.collection.group(
              :cond => {:ploc => {'$within' => {'$box' => box}}, :deleted_at => {'$exists' => false}},
              :key => 'uid',
              :initial => {count: 0},
              :reduce => "function(obj,prev) {prev.count++}"
          )

          popular_counts.sort! { |x, y| y["count"] <=> x["count"] }

          if popular_counts.length > MAX_POPULAR
            popular_counts = popular_counts[0, MAX_POPULAR]
          end

          popular = []

          popular_counts.each do |person|
            member = User.find(person["uid"])
            if member != page_owner
              popular << {
                  "name" => member.username.downcase,
                  "pic" => member.thumb_url,
                  "count" => person["count"].to_i,
                  "url" => user_path(member)+"?"+location.to_query
              }
            end
            if member == page_owner
              @users['owner'] = true
            end
          end

          popular.sort! { |x, y| [y["count"], x["name"]] <=> [x["count"], y["name"]] }

          @users["popular"] = popular
        end
      end
    end

    respond_to do |format|
      format.json { render :json => @users }
    end

  end

  def magazine
    @user = User.find_by_username(params[:id])
    raise ActionController::RoutingError.new('Not Found') unless !@user.nil?

    if !cookies[:page_state].nil?
      page_state = JSON.parse(cookies[:page_state])
      if page_state.has_key?(@user.username) && page_state[@user.username].has_key?("filterType") && page_state[@user.username]["filterType"] == "tag"
        @tag = page_state[@user.username]["filterValue"]
      end
    else
      page_state = {}
      @tag = nil
    end

    if params[:start].nil?
      params[:start] = 0
    end

    start_pos = params[:start].to_i
    count = 20

    if params[:lat].nil? or params[:lng].nil?
      if @tag
        @perspectives = @user.perspectives.where(:tags.in => [@tag]).order_by([:created_at, :desc]).skip(start_pos).limit(count).entries
      else
        @perspectives = @user.perspectives.order_by([:created_at, :desc]).skip(start_pos).limit(count).entries
      end
      @lat = nil
      @lng = nil
    else
      @lat = params[:lat].to_f
      @lng = params[:lng].to_f

      # Text input will convert to 0.0
      if @lat != 0.0 && @lng != 0.0
        # Tried to use mongoid.near but consistently returned incorrect results
        # First ~20 results would be correct but then no longer in correct distance
        # Sample queries: 
        # @perspectives = @user.perspectives.where(:ploc => {'$near'=>[@lat, @lng]}).entries[start_pos..(start_pos + count - 1)]
        # @perspectives = @user.perspectives.near(:ploc => [@lat, @lng]).entries[start_pos..(start_pos + count - 1)]
        #

        if @tag
          raw_perspectives = @user.perspectives.where(:tags.in => [@tag]).entries
        else
          raw_perspectives = @user.perspectives.all().entries
        end
        raw_perspectives.each do |perp|
          perp.distance = haversine_distance(@lat, @lng, perp.ploc[0], perp.ploc[1])["m"]
        end

        raw_perspectives.sort! { |a, b| a.distance <=> b.distance }

        finish = start_pos + count - 1
        if finish >= raw_perspectives.length
          finish = raw_perspectives.length - 1
        end
        @perspectives = raw_perspectives[start_pos..(start_pos+count-1)]
      else
        @lat = nil
        @lng = nil
        if @tag
          @perspectives = @user.perspectives.where(:tags.in => [@tag]).order_by([:created_at, :desc]).skip(start_pos).limit(count).entries
        else
          @perspectives = @user.perspectives.order_by([:created_at, :desc]).skip(start_pos).limit(count).entries
        end
      end
    end

    if @perspectives.length < count
      @noscroll = true
    end

    if @lat && @lng
      if !page_state.has_key?(@user.username)
        page_state[@user.username] = {}
      end

      page_state[@user.username]["lat"] = @lat
      page_state[@user.username]["lng"] = @lng

      cookies[:page_state] = {:value => page_state.to_json}
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def current_location
    @user = User.find_by_username(params[:id])
    if current_user && @user.id != current_user.id
      raise ActionController::RoutingError.new('Not Found')
    end

    respond_to do |format|
      format.html { render :location }
    end
  end

  def account
    @user = User.find_by_username(params[:id])
    if @user.id != current_user.id
      raise ActionController::RoutingError.new('Not Found')
    end

    @facebook = false
    @user.authentications.each do |auth|
      if auth.p == "facebook"
        @facebook = true
      end
    end

    respond_to do |format|
      format.html { render :account }
      format.json
    end
  end

  def notifications

    if params[:start]
      @notifications = current_user.notifications(params[:start].to_i, 20)
    else
      @notifications = current_user.notifications(0, 20)
    end

    current_user.notification_count=0 #clear out notifications, as they've been read
    current_user.save

    respond_to do |format|
      format.json { render :json => {:status => "success", :notifications => @notifications.as_json({:current_user => current_user, :details => true})} }
    end
  end

  def confirm_username
    @user = User.find_by_username(params[:id])

    if @user != current_user
      return redirect_to account_user_path(current_user)
    end

    respond_to do |format|
      format.html { render :username }
    end
  end

  def update_username
    @user = User.find_by_username(params[:id])

    if @user.id != current_user.id
      return redirect_to account_user_path(current_user)
    end

    @user.update_attributes(params[:user])

    if @user.save
      if session[:"user_return_to"]
        redirect_to session[:"user_return_to"]
      else
        redirect_to account_user_path(@user)
      end
    else
      render :username
    end
  end

  def pic
    @user = User.find_by_username(params[:id])
    if @user.id != current_user.id
      raise ActionController::RoutingError.new('Not Found')
    end

    respond_to do |format|
      format.html
    end
  end

  def update_pic
    @user = User.find_by_username(params[:id])
    if @user.id != current_user.id
      raise ActionController::RoutingError.new('Not Found')
    end

    if params[:user].blank?
      return redirect_to pic_user_path(@user)
    else
      @user.avatar = params[:user][:avatar]
    end

    if @user.save
      respond_to do |format|
        format.html { render :crop_pic }
      end
    else
      respond_to do |format|
        format.html { render :pic }
      end
    end

  end

  def update_location
    @user = User.find_by_username(params[:id])
    if @user.id != current_user.id
      raise ActionController::RoutingError.new('Not Found')
    end

    if params[:lat] && params[:lng]
      lat = params[:lat].to_f
      lng = params[:lng].to_f

      valid_params = true
      if lat > 90 || lat < -90 || lat == 0.0 #0.0 is text converted to float
        valid_params = false
      end

      if lng > 180 || lng < -180 || lng == 0.0
        valid_params = false
      end

      if valid_params
        @user.loc = []
        @user.loc[0] = lat
        @user.loc[1] = lng

        grg = GoogleReverseGeocode.new
        raw_address = grg.reverse_geocode(lat, lng)

        city = "" # Default value if no successful reverse geocode
        if !raw_address.nil? && !raw_address.address_components.nil?
          raw_address.address_components.each do |piece|
            if piece.types.include?('locality')
              city = piece.short_name
            end
          end
        end

        @user.city = city

        @user.save
      end
    end

    respond_to do |format|
      format.html { redirect_to account_user_path(@user), notice: 'Map center updated' }
    end
  end

  def update
    @user = User.find_by_username(params[:id])
    return unless @user.id == current_user.id

    if params[:api_call]
      #intentionally only takes one password (for now)
      @user.description = params[:description]
      @user.url = params[:url]
      lat = params[:user_lat].to_f
      lng = params[:user_lng].to_f
      if lat and lng
        @user.location = [lat, lng]
        @user.city = ""
      end

      if params[:email] && params[:email] != @user.email
        #update email logic coming soon
      end

      if params[:city]
        #update email logic coming soon
        @user.city = params[:city]
      end

      if params[:image]
        @user.avatar = params[:image]
      end
    else
      # Couldn't use update_attributes here as Mongoid wouldn't create new objects
      # where previously <nil>
      @user.update_attributes(params[:user])

      if params[:user][:x]
        @user.x = 2 * params[:user][:x].to_f
      end
      if params[:user][:y]
        @user.y = 2 * params[:user][:y].to_f
      end
      if params[:user][:w]
        @user.w = 2 * params[:user][:w].to_f
      end
      if params[:user][:h]
        @user.h = 2 * params[:user][:h].to_f
      end
    end

    if @user.save
      flash[:notice] = "User Setting Saved!"
      respond_to do |format|
        format.html { render :account }
        format.json { render :json => {:status => "success", :user => @user.as_json({:current_user => current_user})} }
      end
    else
      respond_to do |format|
        format.html { render :account }
        format.json { render :json => {:status => "fail", :message => @user.errors} }
      end
    end
  end

  def suggested
    lat = params[:lat].to_f
    lng = params[:lng].to_f

    if lng.nil? or lng == 0
      lng = params[:long].to_f
    end

    if lng > 180 or lng < -180 or lat > 180 or lat < -180
      #for some reason, is not a proper co-ordinate
      @users = []
      logger.warn "#WARN #INPUTERROR Suggested user search with co-ordinates not on earth"
    else
      @users = User.top_nearby(lat, lng, 25)
    end

    if current_user
      @users.delete(current_user)
    end

    respond_to do |format|
      format.json { render :json => {:suggested => @users.as_json({:current_user => current_user})} }
    end
  end

  def confirm_destroy
    @user = User.find_by_username(params[:id])
    return unless @user.id == current_user.id

    respond_to do |format|
      format.html
    end
  end

  def destroy
    @user = User.find_by_username(params[:id])
    return unless @user.id == current_user.id

    sign_out(current_user)
    Resque.enqueue(DestroyUser, @user.id)

    respond_to do |format|
      format.html { redirect_to "/" }
    end
  end

  def follow
    @user = User.find_by_username(params[:id])

    current_user.follow(@user)

    @user.save!
    current_user.save!

    track! :follow
    ActivityFeed.add_follow(current_user, @user)

    respond_to do |format|
      format.html { render :show }
      format.js
      format.json { render :text => "OK" }
    end
  end

  def unfollow
    @user = User.find_by_username(params[:id])

    current_user.unfollow(@user)
    current_user.save

    respond_to do |format|
      format.html { render :show }
      format.js
      format.json { render :text => "OK" }
    end
  end

  def block
    @user = User.find_by_username(params[:id])

    current_user.blocked_users << @user.id
    current_user.save!

    respond_to do |format|
      format.js
      format.json { render :text => "OK" }
    end
  end

  def unblock
    @user = User.find_by_username(params[:id])

    current_user.blocked_users.delete(@user.id)
    current_user.save

    respond_to do |format|
      format.js
      format.json { render :text => "OK" }
    end
  end

  def download
    @user = User.find_by_username(params[:id])

    if current_user != @user
      current_user.follow(@user)
      @user.save!
    end

    current_user.first_run.dismiss_app_ad = true

    current_user.save!

    if current_user != @user
      ActivityFeed.add_follow(current_user, @user)
    end

    respond_to do |format|
      return redirect_to app_path
    end
  end

  def followers
    @user = User.find_by_username(params[:id])
    #this is the final step in routes, if this doesn't work its a 404 -iMack
    raise ActionController::RoutingError.new('Not Found') unless !@user.nil?

    start_pos = params[:start].to_i
    count = 20

    @users = @user.followers.skip(start_pos).limit(count)
    @title = t('user.follower_title', :username => @user.username)

    respond_to do |format|
      format.json { render :json => {:users => @users} }
      format.html { render :template => 'users/list' }
      format.js { render :template => 'users/list' }
    end
  end

  def following
    @user = User.find_by_username(params[:id])
    #this is the final step in routes, if this doesn't work its a 404 -iMack
    raise ActionController::RoutingError.new('Not Found') unless !@user.nil?

    start_pos = params[:start].to_i
    count = 20

    @users = @user.following.skip(start_pos).limit(count).entries
    @title = t('user.following_title', :username => @user.username)

    respond_to do |format|
      format.html { render :template => 'users/list' }
      format.json { render :json => {:users => @users} }
      format.js { render :template => 'users/list' }
    end
  end

  def index
    follow_filter = params[:filter_follow]

    @place = Place.forgiving_find(params[:place_id])

    @users = []

    if !follow_filter
      @perspectives = @place.perspectives
    elsif current_user
      @perspectives = current_user.following_perspectives_for_place(@place)
    else
      @perspectives = []
    end

    for perspective in @perspectives
      @users << perspective.user
    end

    respond_to do |format|
      format.html
      format.json { render :json => {:users => @users.as_json({:current_user => current_user})} }
    end
  end

  def activity
    @user = User.find_by_username(params[:id])

    @activities = @user.activity_feed.activities

    respond_to do |format|
      format.html
      format.json { render :json => {:user_feed => @activities.as_json()} }
    end

  end

  def unsubscribe
    @user = User.find_by_crypto_key(params[:ck])

    @user.user_settings.weekly_email = false
    @user.save

    respond_to do |format|
      format.html
    end
  end

  def resubscribe
    @user = User.find_by_crypto_key(params[:ck])

    @user.user_settings.weekly_email = true
    @user.save

    respond_to do |format|
      format.html { redirect_to "/" }
    end
  end

  def resend
    @user = User.find_for_database_authentication({:login => params['username']})

    if @user
      Devise::Mailer.confirmation_instructions(@user).deliver

      respond_to do |format|
        format.json { render :json => {:status => "OK"} }
      end
    else
      respond_to do |format|
        format.json { render :json => {:status => "INVALID EMAIL"} }
      end
    end
  end
end
