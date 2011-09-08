class RegistrationsController < Devise::RegistrationsController

  include Devise::Controllers::InternalHelpers

  def create

    if params[:format] != "json" #or params[:api_call]
      super
      return
    end

    #intentionally only takes one password (for now)
    user = User.new(:username =>params[:username],
                    :email =>params[:email],
                    :password =>params[:password],
                    :confirmation_password =>params[:password])

    user.facebook_access_token = params[:facebook_access_token]

    lat = params[:lat].to_f
    long = params[:long].to_f
    user.location = [lat, long]

    user[:fbDict] = params[:fbDict]

    if user.save
      if current_client_application
        #send back some access keys so user can immediately start
        request_token = current_client_application.create_request_token
        request_token.authorize!( user )
        request_token.provided_oauth_verifier = request_token.verifier
        access_token = request_token.exchange!

        respond_to do |format|
          format.json { render :json => {:access_token_key => access_token.key, :access_token_secret =>access_token.secret} }
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
end