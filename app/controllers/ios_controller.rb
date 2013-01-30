class IosController < ApplicationController
  before_filter :login_required

  def update_token

    current_user.ios_notification_token = params[:ios_notification_token]
    current_user.save

    respond_to do |format|
      format.json { render :json => {:status => 'OK'} }
    end
  end

  def update_location

    lat = params[:lat].to_f
    lng = params[:lng].to_f
    accuracy = params[:accuracy].to_f
    Rails.logger.info "Got a location for #{current_user.username}: #{lat}, #{lng} with accuracy #{accuracy}"

    respond_to do |format|
      format.json { render :json => {:status => 'OK'} }
    end
  end

end
