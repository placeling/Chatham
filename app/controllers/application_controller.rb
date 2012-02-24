require 'json'

class ApplicationController < ActionController::Base
  include HTTParty
  
  # protect_from_forgery TODO: might want this back
  before_filter :api_check, :set_session_return_path
  
  helper_method :user_location
  
  alias :logged_in? :user_signed_in?

  use_vanity :current_user

  def after_sign_in_path_for(resource)
    return (session[:"user.return_to"].nil?) ? "/" : session[:"user.return_to"].to_s
  end
  
  def after_sign_out_path_for(resource)
    return (session[:"user.return_to"].nil?) ? request.referer : session[:"user.return_to"].to_s
  end
  
  def after_create(resource)
    return (session[:"user.return_to"].nil?) ? "/" : session[:"user.return_to"].to_s
  end
  
  def set_session_return_path
    # Last case is for use case where user fails to connect via 3rd party auth so signs in manually
    if request.path == new_user_session_path && URI(request.referer).path != new_user_session_path && URI(request.referer).path[0..4] != "/auth"
      session[:"user.return_to"] = URI(request.referer).path
    # Following line handles user attaching 3rd party auth to their account
    elsif current_user && request.path == account_user_path(current_user)
      session[:"user.return_to"] = account_user_path(current_user)
    end
  end
  
  def api_check
    if params[:api_call]
      oauth_app_required
    end
  end
  
  def login_required
    login_or_oauth_required
    if current_user.nil?
      authenticate_user!
    end
  end
  
  def admin_required
    #this is the method used in oauth_clients_controller, rename for devise
    authenticate_user!
    if !current_user.is_admin?
      flash[:message] = t 'admin.required_failed'
      redirect_to "/"
    end
  end

  def admin_user?
    if current_user
      return current_user.is_admin?
    else
      return false
    end
  end
  
  def user_location
    if !params[:api_call] && Rails.env != "test"
      if !cookies[:location]
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
  
  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  #oauth-plugin needs this
  def current_user=(user)
    @current_user = user
  end

end
