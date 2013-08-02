require 'json'

class ApplicationController < ActionController::Base
  include HTTParty

  # protect_from_forgery TODO: might want this back
  before_filter :api_check, :set_location

  helper_method :user_location
  helper_method :return_to_link

  alias :logged_in? :user_signed_in?

  def return_to_link
    if session[:"user_return_to"]
      session[:"user_return_to"]
    else
      if !current_user.nil?
        user_path(current_user)
      end
    end
  end

  def after_sign_out_path_for(resource)
    if session[:"user_return_to"]
      return session[:"user_return_to"].to_s
    elsif request.referer
      return request.referer
    else
      return "/"
    end
  end

  def api_check
    if params[:api_call] && !Rails.env.test?
      if params[:key] && request.get?
        if ClientApplication.find_by_key(params[:key]).nil?
          oauth_app_required
        end
      else
        oauth_app_required
      end
    end
  end

  def login_required
    login_or_oauth_required
    if current_user.nil?
      if request.get?
        session[:"user_return_to"] = request.fullpath
      else
        session[:"user_return_to"] = URI(request.referer).path unless request.referer.nil?
      end
      authenticate_user!
    end
  end

  def admin_required
    #this is the method used in oauth_clients_controller, rename for devise
    if request.get?
      session[:"user_return_to"] = request.fullpath
    else
      session[:"user_return_to"] = URI(request.referer).path unless request.referer.nil?
    end
    authenticate_user!
    if !current_user.is_admin?
      flash[:message] = t 'admin.required_failed'
      redirect_to "/"
    end
  end

  def permitted_publisher
    if params[:publisher_id] || params[:id]
      @publisher = Publisher.find(params[:publisher_id] || params[:id])
      unless Publisher.available_for(current_user).include?(@publisher)
        redirect_to publishers_path
      end
    end
  end

  def admin_user?
    if current_user
      return current_user.is_admin?
    else
      return false
    end
  end

  def get_location
    location = {
        "default" => {
            "lat" => "49.2820",
            "lng" => "-123.1079"
        }
    }

    if current_user && current_user.location && current_user.location.length == 2
      location["user"] = {
          "lat" => (current_user.location[0] * 100).round().to_f/100,
          "lng" => (current_user.location[1] * 100).round().to_f/100
      }
    end

    geo = GeoIP.new("#{Rails.root}/config/GeoIPCity.dat")
    c = geo.city(request.remote_ip)

    if !c.nil?
      location["remote_ip"] = {
          "lat" => c.latitude,
          "lng" => c.longitude
      }
    else
      location["no_ip"] = true
    end

    return location
  end

  def user_location
    if !params[:api_call] && Rails.env != "test"
      if !cookies[:location]
        location = get_location

        cookies[:location] = {:value => location.to_json, :expires => 1.day.from_now}
      else
        location = JSON.parse(cookies[:location])
        modified = false
        if !location.has_key?("user") && current_user && current_user.location && current_user.location.length == 2
          location["user"] = {
              "lat" => (current_user.location[0]*100).round().to_f/100,
              "lng" => (current_user.location[1]*100).round().to_f/100
          }
          modified = true
        end

        if !location.has_key?("remote_ip") && !location.has_key?("no_ip")
          geo = GeoIP.new("#{Rails.root}/config/GeoIPCity.dat")
          c = geo.city(request.remote_ip)

          if !c.nil?
            location["remote_ip"] = {
                "lat" => c.latitude,
                "lng" => c.longitude
            }
            modified = true
          end
        end

        if modified == true
          cookies[:location] = {:value => location.to_json, :expires => 1.day.from_now}
        end
      end
    end
  end

  def set_location
    location = get_location

    if current_user && current_user.location && current_user.location.length == 2
      @default_lat = (current_user.location[0]*100).round().to_f/100
      @default_lng = (current_user.location[1]*100).round().to_f/100
    elsif location.has_key?("remote_ip") && location["remote_ip"]
      @default_lat = location["remote_ip"]["lat"]
      @default_lng = location["remote_ip"]["lng"]
    else
      @default_lat = "49.2820"
      @default_lng = "-123.1079"
    end
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  #oauth-plugin needs this
  def current_user=(user)
    @current_user = user
  end

end
