require 'json'

class ApplicationController < ActionController::Base
  include HTTParty
  
  # protect_from_forgery TODO: might want this back
  before_filter :api_check, :set_p3p
  
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
  
  def api_check
    if params[:api_call]
      if params[:key] && request.get?
        if ClientApplication.find_by_key( params[:key] ).nil?
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
        session[:"user.return_to"] = request.fullpath
      else
        session[:"user.return_to"] = URI(request.referer).path
      end
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
  
  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  #oauth-plugin needs this
  def current_user=(user)
    @current_user = user
  end
  
  private
  # P3P headers for IE8 iFrame: http://robanderson123.wordpress.com/2011/02/25/p3p-header-hell/
  # this is required by IE so that we can set session cookies
  def set_p3p
    headers['P3P'] = 'CP="ALL DSP COR CURa ADMa DEVa OUR IND COM NAV"'
  end
end
