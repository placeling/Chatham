class AuthenticationsController < ApplicationController
  before_filter :login_required, :only =>[:friends, :add]

  def index
    @authentications = current_user.authentications if current_user
  end

  def login
    provider = params['provider']
    uid = params['uid']
    token = params["token"]
    expiry = params["expiry"]

    if token && !uid
      fb_user = get_me token
      uid = fb_user.identifier
    end

    auth = Authentication.find_by_provider_and_uid(provider, uid)

    if auth && auth.token == token
      render :text => generate_keys_for( auth.user )
    elsif auth && (fb_user || fb_user = get_me( token ) )
      if fb_user.identifier == auth.uid
        #this is kind of an odd case, but we shoudl probably update the token
        auth.token = token
        auth.save!

        render :text => generate_keys_for( auth.user )
      else
        render :text =>"FAIL"
      end
    else
      render :text =>"FAIL"
    end
  end

  def add
    provider = params['provider']
    uid = params['uid']
    token = params["token"]
    expiry = params["expiry"]

    fb_user = get_me token #verifies that token is good
    if fb_user.nil? or (uid && uid != fb_user.identifier)
      render :json =>{:status => "FAIL"} #invalid token
      return
    end

    uid = fb_user.identifier unless !uid.nil?
    auth = Authentication.find_by_provider_and_uid(provider, uid)

    if current_user && auth && current_user.id != auth.user.id
      render :json => "Facebook id already in use", :status=>400
    elsif current_user && auth && auth.token == token
      render :json => {:user => current_user.as_json({:current_user => current_user})}
    elsif current_user && auth  && auth.uid == uid
      #update tokens
      auth.token = token
      auth.save
      render :json =>{:user => current_user.as_json({:current_user => current_user})}
    elsif current_user
      #some update
      auth = current_user.authentications.create!(:provider => provider, :uid => uid, :token =>token, :expiry=>expiry)
      auth.save
      render :json => {:user => current_user.as_json({:current_user => current_user})}
    else
      render :json =>{:status => "FAIL"}
    end
  end


  def create
    omniauth = request.env["omniauth.auth"]
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    if authentication
      authentication.token = omniauth['credentials']['token'] #update token for facebook
      authentication.save

      sign_in( authentication.user )
      respond_to do |format|
        format.html { redirect_to return_to_link }
        format.json {
          render :text => generate_keys_for( authentication.user )
        }
      end
    elsif current_user
      # Only occurs if already logged in and try to add your Facebook account
      current_user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'], :token => omniauth['credentials']['token'])
      redirect_to return_to_link
    else
      @user = User.new
      @user.password = Devise.friendly_token[0,20]
      @user.apply_omniauth( omniauth )

      if @user.valid?

        if @user.location.nil?
          loc = get_location
          if loc && loc["remote_ip"]
            @user.location =  [ loc["remote_ip"]["lat"], loc["remote_ip"]["lng"] ]
          end
        end

        @user.confirm!
        @user.save!
        @user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'], :token => omniauth['credentials']['token'])
        sign_in( @user )
        respond_to do |format|
          format.html { redirect_to( confirm_username_user_path( @user ) ) }
          format.json {
            render :text => generate_keys_for( authentication.user )
          }
        end
      else
        Rails.logger.warn( @user.errors )
        @provider = omniauth['provider']
        respond_to do |format|
          format.html {render :auth_fail}
        end
      end
    end
  end

  def friends

    provider = params['provider']
    @users = []

    if provider == "facebook" && current_user.facebook

      friends_json = $redis.smembers("facebook_friends_#{current_user.id}")
      @users = []
      if friends_json.count > 0 #friend self to differentiate empty from null
        friends_json.each do |friend_json|
          friend = JSON.parse( friend_json )
          user = User.find( friend[0] )
          user.fullname = friend[2]
          @users << user
        end
      else
        $redis.sadd("facebook_friends_#{current_user.id}" , [current_user.id, current_user.facebook.fetch.identifier, current_user.facebook.fetch.name].to_json )
        friends = current_user.facebook.friends

        begin
          friends.each do |friend|
            if auth = Authentication.find_by_provider_and_uid(provider, friend.identifier)
              auth.user.fullname = friend.name
              @users << auth.user
              $redis.sadd("facebook_friends_#{current_user.id}" , [auth.user.id, friend.identifier, friend.name].to_json )
            end
          end
          friends = friends.next
        end while friends.count > 0

      end
    end

    @users.sort! {|x,y| x.fullname <=> y.fullname }

    respond_to do |format|
      format.json { render :json => {:users => @users.as_json({ :current_user => current_user }) } }
    end

  end


  def destroy
    @authentication = current_user.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = "Successfully destroyed authentication."
    redirect_to authentications_url
  end

  protected

  def generate_keys_for( user )
    # get rid of old auth tokens

    #user.remove_tokens_for( current_client_application )

    request_token = current_client_application.create_request_token
    request_token.authorize!( user )
    request_token.provided_oauth_verifier = request_token.verifier
    access_token = request_token.exchange!
    return access_token.to_query + "&username=#{user.username}"
  end


  def get_me( token )
    user = FbGraph::User.me( token ) #see if the given token is any good
    begin
      return user.fetch
    rescue
      return nil
    end
  end

end
