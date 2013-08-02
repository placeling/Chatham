class AuthenticationsController < ApplicationController
  before_filter :login_required, :only => [:friends, :add]

  def index
    @authentications = current_user.authentications if current_user
  end

  def login
    provider = params['provider']
    uid = params['uid']
    token = params["token"]
    expiry = params["expiry"]

    send_json = !params["newlogin"].nil?

    if token && !uid
      fb_user = get_me token
      uid = fb_user['id']
    end

    auth = Authentication.find_by_provider_and_uid(provider, uid)

    if auth && auth.token == token
      if send_json
        render :json => {:status => "success", :token => generate_keys_for(auth.user), :user => auth.user.as_json({:current_user => auth.user, :perspectives => :created_by})}
      else
        render :text => generate_keys_for(auth.user)
      end

    elsif auth && (fb_user || fb_user = get_me(token))
      if fb_user['id'] == auth.uid
        #this is kind of an odd case, but we shoudl probably update the token
        auth.token = token
        auth.save!

        if send_json
          render :json => {:status => "success", :token => generate_keys_for(auth.user), :user => auth.user.as_json({:current_user => auth.user, :perspectives => :created_by})}
        else
          render :text => generate_keys_for(auth.user)
        end
      else
        render :json => {:status => "fail"}
      end
    else
      render :json => {:status => "fail"}
    end
  end

  def add

    provider = params['provider']
    uid = params['uid']
    token = params["token"]
    expiry = params["expiry"]
    secret = params["secret"]


    if provider == "facebook"
      process_facebook(uid, token, expiry)
    elsif provider == "twitter"
      process_twitter(uid, token, secret)
    end

  end


  def create
    omniauth = request.env["omniauth.auth"]
    send_json = !params["newlogin"].nil?
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    if authentication
      authentication.token = omniauth['credentials']['token'] #update token for facebook

      if omniauth['credentials']['expires'] && omniauth['credentials']['expires_at']
        expiry_timestamp = omniauth['credentials']['expires_at']
        authentication.expiry = Time.at(expiry_timestamp).to_s
        authentication.expires_at = Time.at(expiry_timestamp)
      end

      authentication.save

      sign_in(authentication.user)
      respond_to do |format|
        format.html { redirect_to return_to_link }
        format.json {
          if send_json
            render :json => {:status => "success", :token => generate_keys_for(auth.user), :user => auth.user.as_json({:current_user => auth.user, :perspectives => :created_by})}
          else
            render :text => generate_keys_for(auth.user)
          end
        }
      end
    elsif current_user
      # Only occurs if already logged in and try to add your Facebook account
      current_user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'], :token => omniauth['credentials']['token']) do |a|
        if omniauth['credentials']['expires'] && omniauth['credentials']['expires_at']
          expiry_timestamp = omniauth['credentials']['expires_at']
          a.expiry = Time.at(expiry_timestamp).to_s
          a.expires_at = Time.at(expiry_timestamp)
        end
      end
      redirect_to return_to_link
    else
      @user = User.new
      @user.password = Devise.friendly_token[0, 20]
      @user.apply_omniauth(omniauth)

      if @user.valid?

        if @user.location.nil?
          loc = get_location
          if loc && loc["remote_ip"]
            @user.location = [loc["remote_ip"]["lat"], loc["remote_ip"]["lng"]]
          end
        end

        @user.confirm!
        #Notifier.welcome(@user.id).deliver!

        @user.save!
        @user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'], :token => omniauth['credentials']['token']) do |a|
          if omniauth['credentials']['expires'] && omniauth['credentials']['expires_at']
            expiry_timestamp = omniauth['credentials']['expires_at']
            a.expiry = Time.at(expiry_timestamp).to_s
            a.expires_at = Time.at(expiry_timestamp)
          end
        end

        sign_in(@user)

        respond_to do |format|
          format.html { redirect_to(confirm_username_user_path(@user)) }
          format.json {
            if send_json
              render :json => {:status => "success", :token => generate_keys_for(auth.user), :user => auth.user.as_json({:current_user => auth.user, :perspectives => :created_by})}
            else
              render :text => generate_keys_for(auth.user)
            end
          }
        end
      else
        Rails.logger.warn(@user.errors)
        @provider = omniauth['provider']
        respond_to do |format|
          format.html { render :auth_fail }
        end
      end
    end
  end



  def destroy
    @authentication = current_user.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = "Successfully destroyed authentication."
    redirect_to authentications_url
  end

  protected


  def process_facebook(uid, token, expiry)
    provider = "facebook"
    fb_user = get_me token #verifies that token is good
    if fb_user.nil? or (uid && uid != fb_user['id'])
      render :json => {:status => "FAIL"} #invalid token
      return
    end

    uid = fb_user['id'] unless !uid.nil?
    auth = Authentication.find_by_provider_and_uid(provider, uid)

    if current_user && auth && current_user.id != auth.user.id
      render :json => "Facebook id already in use", :status => 400
    elsif current_user && auth && auth.token == token
      auth.expiry = expiry
      auth.save
      render :json => {:user => current_user.as_json({:current_user => current_user})}
    elsif current_user && auth && auth.uid == uid
      #update tokens
      auth.token = token
      auth.expiry = expiry
      auth.save!
      render :json => {:user => current_user.as_json({:current_user => current_user})}
    elsif current_user
      #some update
      auth = current_user.authentications.create!(:provider => provider, :uid => uid, :token => token, :expiry => expiry)
      render :json => {:user => current_user.as_json({:current_user => current_user})}
    else
      render :json => {:status => "FAIL"}
    end
  end

  def process_twitter(uid, token, secret, provider = "twitter")
    auth = Authentication.find_by_provider_and_uid(provider, uid)

    if current_user && auth && auth.uid == uid && current_user.id == auth.user.id
      #update tokens
      auth.token = token
      auth.secret = secret
      auth.save!
      render :json => {:user => current_user.as_json({:current_user => current_user})}
    elsif current_user
      #some update
      auth = current_user.authentications.create!(:provider => provider, :uid => uid, :token => token, :expiry => "", :secret => secret)
      render :json => {:user => current_user.as_json({:current_user => current_user})}
    else
      render :json => {:status => "FAIL"}
    end


  end


  def generate_keys_for(user)
    # get rid of old auth tokens

    #user.remove_tokens_for( current_client_application )
    return "" unless !current_client_application.nil? #mostly for testing where there isn't a live application

    request_token = current_client_application.create_request_token
    request_token.authorize!(user)
    request_token.provided_oauth_verifier = request_token.verifier
    access_token = request_token.exchange!
    return access_token.to_query + "&username=#{user.username}"
  end


  def get_me(token)
    user = Koala::Facebook::API.new(token) #see if the given token is any good
    begin
      return user.get_object("me")
    rescue
      return nil
    end
  end

end
