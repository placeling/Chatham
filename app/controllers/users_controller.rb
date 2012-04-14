require 'json'

NEARBY_RADIUS = 0.0035
DEFAULT_LAT = 49.9
DEFAULT_LNG = -97.1
DEFAULT_ZOOM = 3
DEFAULT_EMBED_ZOOM = 15
DEFAULT_WIDTH = 450
DEFAULT_HEIGHT = 500

class UsersController < ApplicationController

  before_filter :login_required, :only =>[:me, :update, :follow, :unfollow, :add_facebook, :edit, :update, :account]
  
  
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

  def edit
    @user = User.find_by_username(params[:id])
    raise ActionController::RoutingError.new('Not Found') unless !@user.nil?

    if current_user.id != @user.id
      redirect_to edit_user_path( current_user )
    else
      if params[:avatar]
        render :pic
      else
        respond_to do |format|
          format.html
          format.json
        end
      end
    end

  end

  def create
    return unless params[:format] == :json

    lat = params[:lat].to_f
    lng = params[:long].to_f

    if (params[:facebook_access_token])
      user = User.new(:username =>params[:username].strip,
            :email =>params[:email], :password => Devise.friendly_token[0,20])

      if user.valid?
        #these trigger an implicit save that seems to override validations
        user.confirm! #indicates that it doesn't need a confirmation, since we got email from Facebook
        auth = user.authentications.build(:provider => "facebook", :uid =>params[:facebook_id], :token => params[:facebook_access_token])
      end
    else
      user = User.new(:username =>params[:username].strip,
                  :email =>params[:email],
                  :password =>params[:password],
                  :confirmation_password =>params[:password])
    end

    if  lat != 0 && lng !=0
      user.location = [lat, lng]
    else
      loc = get_location
      if location["remote_ip"]
        user.location =  [ location["remote_ip"]["lat"], location["remote_ip"]["lng"] ]
      end
    end

    if user.save
      auth.save! unless auth.nil?

      if current_client_application
        #send back some access keys so user can immediately start
        request_token = current_client_application.create_request_token
        request_token.authorize!( user )
        request_token.provided_oauth_verifier = request_token.verifier
        access_token = request_token.exchange!

        respond_to do |format|
          format.json { render :json => {:status =>"success", :token => access_token.to_query } }
        end
      else
        respond_to do |format|
          format.json { render :json => {:status =>"success"} }
        end
      end
    else
      Airbrake.notify( params )
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
      format.json { render :json => {:status =>"success", :users => @users.as_json({:current_user => current_user}) } }
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
    @height = DEFAULT_HEIGHT
    @width = DEFAULT_WIDTH
    
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
        persp = Perspective.where({'uid'=>@user._id, '_id'=>params[:pid]}).first
        
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
        if page_state.has_key?(@user.username)
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
          
          perps = Perspective.where(:ploc.within => {"$center" => [loc,0.05]}, :uid => @user.id)
          
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
      if top_lat == 90.0
        top_lat = 89.999999
      end
      if bottom_lat == -90.0
        bottom_lat = -89.999999
      end
      if right_lng == 180.0
        right_lng = 179.999999
      end
      if right_lng == -180.0
        right_lng = -179.999999
      end
      if left_lng == 180.0
        left_lng = 179.999999
      end
      if left_lng == -180
        left_lng = -179.999999
      end
      # Edge case where user zooms so far out on map that multiple earths are visible
      if valid_params && right_lng < left_lng
        right_lng, left_lng = left_lng, right_lng
      end
    end
    
    if valid_params
      @perspectives = Perspective.where(:ploc.within => {"$box" => [[bottom_lat, left_lng],[top_lat, right_lng]]}, :uid => @user.id).includes(:place, :user)
    end
    
    respond_to do |format|
      format.js
    end
  end
  
  def recent
    @user = User.find_by_username(params[:id])
    
    if params[:start].nil?
      params[:start] = 0
    end
    
    start_pos = params[:start].to_i
    count = 20
    
    @perspectives = @user.perspectives.order_by([:created_at, :desc]).skip(start_pos).limit( count )
    
    if @perspectives.length < count
      @noscroll = true
    end
    
    respond_to do |format|
      format.html
      format.js
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
      format.html { render :account}
    end
  end
  
  def confirm_username
    @user = User.find_by_username(params[:id])
    
    if @user != current_user
      return redirect_to edit_user_path( current_user )
    end
    
    respond_to do |format|
      format.html { render :username}
    end
  end
  
  def update_username
    @user = User.find_by_username(params[:id])
    
    if @user != current_user
      return redirect_to edit_user_path( current_user )
    end
    
    if @user.update_attributes(params[:user])
      redirect_to session[:"user_return_to"]
    else
      render :username
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
      
      if params[:email] &&  params[:email] != @user.email
        #update email logic coming soon
      end
      
      if params[:image]
        @user.avatar = params[:image]
      end
    else
      if params[:avatar]
        if params[:user].blank?
          return redirect_to edit_avatar_user_path(@user)
        else
          @user.avatar = params[:user][:avatar]
        end
      else
        # Couldn't use update_attributes here as Mongoid wouldn't create new objects
        # where previously <nil>
        if params[:user][:description]
          @user.description = params[:user][:description]
        end
        if params[:user][:username]
          @user.username = params[:user][:username]
        end
        if params[:user][:email]
          @user.email = params[:user][:email]
        end
        if params[:user][:city] && params[:user][:city].length > 0
          @user.city = params[:user][:city]
        else
          @user.city = nil
        end
        if params[:user][:url] && params[:user][:url].length > 0
          @user.url = params[:user][:url]
        else
          @user.url = nil
        end
        if params[:user][:new_follower_notify]
          @user.new_follower_notify = params[:user][:new_follower_notify]
        end
        if params[:user][:remark_notify]
          @user.remark_notify = params[:user][:remark_notify]
        end
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
    end
    
    if @user.save
      if params[:avatar]
        render :crop_pic
      else
        respond_to do |format|
          format.html { redirect_to account_user_path(@user) }
          format.json { render :json => {:status =>"success", :user => @user.as_json({:current_user => current_user}) } }
        end
      end
    else
      if params[:avatar]
        render :pic
      else
        respond_to do |format|
          format.html { render :edit }
          format.json { render :json => {:status => "fail", :message => @user.errors} }
        end
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
      @users = User.top_nearby( lat, lng, 25 )
    end

    if current_user
      @users.delete( current_user )
    end

    respond_to do |format|
      format.json { render :json=> {:suggested => @users.as_json({:current_user => current_user}) } }
    end
  end

  def follow
    @user = User.find_by_username( params[:id] )

    current_user.follow( @user )

    @user.save!
    current_user.save!

    track! :follow

    respond_to do |format|
      format.html { render :show }
      format.js
      format.json { render :text => "OK" }
    end
  end

  def unfollow
    @user = User.find_by_username( params[:id] )

    current_user.unfollow( @user )
    current_user.save

    respond_to do |format|
      format.html { render :show }
      format.js
      format.json { render :text => "OK" }
    end
  end


  def followers
    @user = User.find_by_username( params[:id] )
    start_pos = params[:start].to_i
    count = 20

    @users = @user.followers.skip(start_pos).limit( count )
    @title = t('user.follower_title', :username =>@user.username)

    respond_to do |format|
      format.json { render :json => {:followers => @users} }
      format.html { render :template => 'users/list'}
    end
  end

  def following
    @user = User.find_by_username( params[:id] )
    start_pos = params[:start].to_i
    count = 20

    @users = @user.following.skip(start_pos).limit( count )
    @title = t('user.following_title', :username =>@user.username)

    respond_to do |format|
      format.html { render :template => 'users/list'}
      format.json { render :json => {:following => @users } }
    end
  end

  def index
    follow_filter = params[:filter_follow]

    if BSON::ObjectId.legal?( params[:place_id] )
      #it's a direct request for a place in our db
      @place = Place.find( params[:place_id])
    else
      @place = Place.find_by_google_id( params[:place_id] )
    end

    @users = []

    if !follow_filter
      @perspectives = @place.perspectives
    elsif current_user
      @perspectives = current_user.following_perspectives_for_place( @place )
    else
      @perspectives = []
    end

    for perspective in @perspectives
      @users << perspective.user
    end

    respond_to do |format|
      format.html
      format.json { render :json => {:users => @users.as_json({:current_user => current_user}) } }
    end
  end


  def activity
    @user = User.find_by_username( params[:id] )

    @activities = @user.activity_feed.activities

    respond_to do |format|
      format.html
      format.json { render :json => {:user_feed => @activities.as_json() } }
    end

  end

  def resend
    @user = User.find_for_database_authentication( {:login => params['username']} )

    if @user
      Devise::Mailer.confirmation_instructions(@user).deliver

      respond_to do |format|
        format.json { render :json => {:status => "OK" } }
      end
    else
      respond_to do |format|
        format.json { render :json => {:status => "INVALID EMAIL" } }
      end
    end
  end
end
