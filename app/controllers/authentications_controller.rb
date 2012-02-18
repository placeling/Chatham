class AuthenticationsController < ApplicationController
  #before_filter :login_required, :only =>[:add]

  def index
    @authentications = current_user.authentications if current_user
  end

  def login
    provider = params['provider']
    uid = params['uid']
    token = params["token"]
    expiry = params["expiry"]

    auth = Authentication.find_by_provider_and_uid(provider, uid)

    if auth && auth.token == token
      render :text => generate_keys_for( auth.user )
    else
      render :text =>"FAIL"
    end
  end

  def add
    provider = params['provider']
    uid = params['uid']
    token = params["token"]
    expiry = params["expiry"]

    auth = Authentication.find_by_provider_and_uid(provider, uid)

    if current_user && auth && current_user.id != auth.user.id  && auth.token == token
      render :json => "Facebook id already in use", :status=>400
    elsif current_user && auth && auth.token == token
      render :json => {:user => current_user.as_json({:current_user => current_user})}
    elsif current_user && auth
      #update tokens
      render :json =>{:status => "FAIL"}
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
      sign_in( authentication.user )
      flash[:notice] = "Signed in successfully."
      respond_to do |format|
        format.html { redirect_to( authentication.user ) }
        format.json {
          render :text => generate_keys_for( authentication.user )
        }
      end

    elsif current_user
      current_user.authentications.create!(:p => omniauth['provider'], :uid => omniauth['uid'])
      flash[:notice] = "Authentication successful."
      redirect_to authentications_url
    else
      user = User.new
      user.apply_omniauth(omniauth)
      if user.save
        flash[:notice] = "Signed in successfully."
        sign_in_and_redirect(:user, user)
      else
        session[:omniauth] = omniauth.except('extra')
        redirect_to new_user_registration_url
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

  def generate_keys_for( user )
    # get rid of old auth tokens

    #user.remove_tokens_for( current_client_application )

    request_token = current_client_application.create_request_token
    request_token.authorize!( user )
    request_token.provided_oauth_verifier = request_token.verifier
    access_token = request_token.exchange!
    return access_token.to_query + "&username=#{user.username}"
  end


end
