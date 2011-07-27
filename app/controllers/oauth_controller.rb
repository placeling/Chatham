require 'oauth/controllers/provider_controller'
class OauthController < ApplicationController
  include OAuth::Controllers::ProviderController

  def access_token_with_xauth_test

    if params[:x_auth_mode] == "client_auth"
      if ! current_client_application.xauth_enabled
        raise Exception.new, t("oauth.no_xauth"), caller
      end

      user = User.find_for_database_authentication( { :login => params[:x_auth_username] } )

      if user.valid_password?( params[:x_auth_password] )
        sign_in (user)
      else
        raise Exception.new,  t("devise.failure.invalid"), caller
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
