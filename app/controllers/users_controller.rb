require 'json'

class UsersController < ApplicationController

  before_filter :login_required, :only =>[:update, :follow, :unfollow, :add_facebook]

  def create
    return unless params[:format] == :json

    lat = params[:lat].to_f
    long = params[:long].to_f

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

    user.location = [lat, long]

    if user.save
      auth.save! unless auth.nil?

      if current_client_application
        track! :signup
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

  def show
    @user = User.find_by_username(params[:id])
    
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
    end
    
    if valid_params
      # Can't figure out how to do mongoid search for correct location parameters so instead
      # get all perspectives and iterate over 'em. Bad code, I know
      perspectives = @user.perspectives
      
      perspectives.each do |persp|
        valid = false
        if persp.loc[0] >= bottom_lat && persp.loc[0] <= top_lat
          if right_lng > left_lng
            if persp.loc[1] <= right_lng && persp.loc[1] >= left_lng
              valid = true
            end
          else
            if (persp.loc[1] >= left_lng || persp.loc[1] <= right_lng)
              valid = true
            end
          end
        end
        
        if valid
          temp = {}
          temp["name"] = persp.place_stub.name
          temp["name_encoded"] = u(persp.place_stub.name)
          temp["uid"] = persp._id
          temp["lowername"] = persp.place_stub.name.downcase
          temp["url"] = perspective_path(persp)
          temp["lat"] = persp.place_stub.loc[0]
          temp["lng"] = persp.place_stub.loc[1]
          
          if !persp.place_stub.street_address.nil? && persp.place_stub.street_address.length > 0
            temp["address"] = persp.place_stub.street_address
          end
          
          temp["categories"] = []
          temp["tags"] = []
          temp["photos"] = []
          temp["modified"] = persp.updated_at.strftime('%B %e, %Y')
          
          if !persp.memo.nil? && persp.memo.length > 0
            temp["memo"] = simple_format(perspective.memo)
          end
          
          if !persp.url.nil? && persp.url.length > 0
            temp["remote_url"] = persp.url
          end
          
          if current_user = @user
            temp["edit"] = edit_perspective_path(persp)
            temp["delete"] = link_to("Delete", persp, :confirm => t("basic.are_you_sure"), :method => :delete, :class => "info_act")
          else
            temp["flag"] = link_to(t("perspective.flag"), flag_perspective_path(persp), :confirm =>t("perspective.flag_confirm"), :method=>"post", :remote=>"true", :class=>"info_act")
            if !persp.memo.nil? || persp.pictures.length > 0
              if current_user && persp.su.include?(current_user.id)
                temp["star"] = unstar_perspective_path(persp)
                temp["starred"] = true
              else
                temp["star"] = star_perspective_path(persp)
                temp["starred"] = false
              end
            end
          end
          
          @perspectives << temp
        end
      end
    end
    
    respond_to do |format|
      format.json {render @perspectives}
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
  
  def update
    @user = User.find_by_username(params[:id])
    return unless @user.id == current_user.id

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

    if @user.save
      respond_to do |format|
        format.json { render :json => {:status =>"success", :user => @user.as_json({:current_user => current_user}) } }
      end
    else
      respond_to do |format|
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

    @user.save!
    current_user.save!

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
    @user = User.find_by_username( params[:username] )

    respond_to do |format|
      format.json { render :json => {:status => "OK" } }
    end
  end

end
