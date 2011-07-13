class XauthController
  before_filter :verify_oauth_consumer_signature
  skip_before_filter :verify_authenticity_token

  def login
    if ! current_client_application.xauth_enabled
      raise Exception.new, "This app does not have xAuth enabled.", caller
    end
    if params[:x_auth_mode] == "client_auth"
      login_params = { :login => params[:x_auth_username], :password => params[:x_auth_password] }
      login_session = UserSession.create( login_params )
      if ! ( login_session and login_session.user )
        raise Exception.new, "Incorrect login or password", caller
      end
    else
      raise Exception.new, "Invalid auth mode", caller
    end

    # Must have a user object or have crashed out
    request_token = current_client_application.create_request_token
    request_token.authorize!(login_session.user)
    request_token.provided_oauth_verifier = request_token.verifier
    access_token = request_token.exchange!
    render :text => access_token.to_query
  end
end