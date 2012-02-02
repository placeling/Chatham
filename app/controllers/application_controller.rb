require 'json'

class ApplicationController < ActionController::Base
  include HTTParty
  debug_output $stdout
  
  # protect_from_forgery TODO: might want this back
  before_filter :api_check
  before_filter :set_login_return_url
  
  helper_method :user_location
  
  alias :logged_in? :user_signed_in?

  use_vanity :current_user

  def after_sign_in_path_for(resource)
    return (session[:"user.return_to"].nil?) ? "/" : session[:"user.return_to"].to_s
  end
  
  def after_sign_out_path_for(resource)
    session[:"user.return_to"] = request.referer
    return (session[:"user.return_to"].nil?) ? "/" : session[:"user.return_to"].to_s
  end
  
  def after_create(resource)
    session[:"user.return_to"] = request.referer
    return (session[:"user.return_to"].nil?) ? "/" : session[:"user.return_to"].to_s
  end
  
  def api_check
    if params[:api_call]
      oauth_app_required
    end
  end

  def login_required
    login_or_oauth_required
    if current_user.nil?
      session[:"user.return_to"] = request.referer
      authenticate_user!
    end
  end
  
  def set_login_return_url
    if request.method == "GET"
      session[:"user.return_to"] = request.referer
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
    if params[:api_call].nil?
      if cookies[:location].nil?
        location = {
          "default" => {
            "lat" => "49.2820",
            "lng" => "-123.1079"
          }
        }

        if current_user && current_user.location.length == 2
          location["user"] = {
            "lat" => current_user.location[0],
            "lng" => current_user.location[1]
          }
        end

        begin
          response = HTTParty.get('http://freegeoip.net/json/'+request.remote_ip)
          if response.code == 200
            geo_json = JSON.parse(response.body)
            location["remote_ip"] = {
              "lat" => geo_json["latitude"],
              "lng" => geo_json["longitude"]
            }
          end
        rescue
          logger.warn "Request to freegeoip failed"
        end

        cookies[:location] = location.to_json
      else
        location = JSON.parse(cookies[:location])
        modified = false
        if !location.has_key?("user") && current_user && current_user.location.length == 2 
          location["user"] = {
            "lat" => current_user.location[0],
            "lng" => current_user.location[1]
          }
          modified = true
        end

        if !location.has_key?("remote_ip")
          begin
            response = HTTParty.get('http://freegeoip.net/json/'+request.remote_ip)
            if response.code == 200
              geo_json = JSON.parse(response.body)
              location["remote_ip"] = {
                "lat" => geo_json["latitude"],
                "lng" => geo_json["longitude"]
              }
              modified = true
            end
          rescue
            logger.warn "Request to freegeoip failed"
          end
        end

        if modified == true
          cookies[:location] = location.to_json
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
