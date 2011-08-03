require 'oauth/controllers/provider_controller'
class OauthController < ApplicationController
  include OAuth::Controllers::ProviderController

  def access_token_with_xauth_test

    if current_client_application.nil?
      render :text => t("oauth.invalid"), :status => 403, :template=>nil
      logger.info "403 - Got invalid Oauth Request"
      return
    end

    if params[:x_auth_mode] == "client_auth"
      if ! current_client_application.xauth_enabled
        logger.info "403 - xauth request for app that doesn't have xauth enabled'"
        render :text => t("oauth.no_xauth"), :status => 403, :template=>nil
        return
      end

      user = User.find_for_database_authentication( { :login => params[:x_auth_username] } )

      if user.valid_password?( params[:x_auth_password] )
        sign_in (user)
      else
        logger.info "401 - Username/Password not valid"
        render :text => t("devise.failure.invalid"), :status => 401, :template=>nil
        return
      end

      # get rid of old auth tokens
      user.tokens.where(:client_application_id =>current_client_application.id).delete_all

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
