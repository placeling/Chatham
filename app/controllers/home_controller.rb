class HomeController < ApplicationController
  before_filter :login_required, :only => [:home_timeline, :logged_in_home]

  def logged_out_home

    respond_to do |format|
      format.html
    end
  end

  def index
    logged_out_home
  end

  def home_timeline
    start_pos = params[:start].to_i
    count = 20

    @activities = current_user.feed(start_pos, count)

    respond_to do |format|
      format.json { render :json => {:home_feed => @activities.as_json(), :user => current_user.as_json()} }
      format.html
    end

  end

  def nearby
    valid_latlng = false
    if params[:lat] && params[:lng]
      valid_lat = false
      valid_lng = false
      if params[:lat]
        lat = params[:lat].to_f
        if lat != 0.0 && lat < 90.0 && lat > -90.0
          valid_lat = true
        end
      end
      if params[:lng]
        lng = params[:lng].to_f
        if lng != 0.0 && lng < 180 && lng > -180
          valid_lng = true
        end
      end
      if valid_lat && valid_lng
        valid_latlng = true
      end
    end

    if valid_latlng
      loc = {}
      loc["lat"] = lat
      loc["lng"] = lng
    else
      loc = get_location
      if loc["remote_ip"]
        loc = loc["remote_ip"]
      else
        loc = loc['default']
      end
    end

    @places = Place.top_nearby_places(loc['lat'].to_f, loc['lng'].to_f, 1, 10)
    @users = User.top_nearby(loc['lat'].to_f, loc['lng'].to_f, 100)

    respond_to do |format|
      format.html
    end

  end

end
