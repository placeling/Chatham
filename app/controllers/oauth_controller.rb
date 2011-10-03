require 'oauth/controllers/provider_controller'
class OauthController < ApplicationController
  include OAuth::Controllers::ProviderController


  def login_fb
    return unless params[:format] == :json
    return unless current_client_application.secret == "kODuCtHsB0poBe62J3FfWB2rCEUeyeYQkEWW0R6i"
    fb_token = params["FBAccessTokenKey"]
    fbid = params["facebook_id"].to_i

    user = User.find_by_facebook_id( fbid )

    if user #&& user.facebook_access_token == fb_token
      #tokens match, authenticated user
      # get rid of old auth tokens
      user.remove_tokens_for( current_client_application )

      request_token = current_client_application.create_request_token
      request_token.authorize!( user )
      request_token.provided_oauth_verifier = request_token.verifier
      access_token = request_token.exchange!
      render :text => access_token.to_query + "&username=#{user.username}"

    else
      render :text => "false"
    end

  end

  def access_token_with_xauth_test

    if current_client_application.nil?
      render :text => t("oauth.invalid"), :status => 401, :template=>nil
      logger.info "401 - Got invalid Oauth Request"
      return
    end

    if params[:x_auth_mode] == "client_auth"
      if ! current_client_application.xauth_enabled
        logger.info "401 - xauth request for app that doesn't have xauth enabled'"
        render :text => t("oauth.no_xauth"), :status => 401, :template=>nil
        return
      end

      user = User.find_for_database_authentication( { :login => params[:x_auth_username] } )

      if !user.nil? && user.valid_password?( params[:x_auth_password] )
        sign_in (user)
      else
        logger.info "401 - Username/Password not valid"
        render :text => "BAD_PASS: " + t("devise.failure.invalid"), :status => 401, :template=>nil
        return
      end

      # get rid of old auth tokens
      user.remove_tokens_for( current_client_application )

      request_token = current_client_application.create_request_token
      request_token.authorize!( user )
      request_token.provided_oauth_verifier = request_token.verifier
      access_token = request_token.exchange!
      render :text => access_token.to_query

    else
      self.access_token
    end
  end

  protected
  # Override this to match your authorization page form
  # It currently expects a checkbox called authorize
  # def user_authorizes_token?
  #   params[:authorize] == '1'
  # end

  # should authenticate and return a users if valid password.
  # This example should work with most Authlogic or Devise. Uncomment it
  # def authenticate_user(username,password)
  #   users = User.find_by_email params[:username]
  #   if users && users.valid_password?(params[:password])
  #     users
  #   else
  #     nil
  #   end
  # end

end
