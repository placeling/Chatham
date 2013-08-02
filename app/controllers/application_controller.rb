require 'json'

class ApplicationController < ActionController::Base
  include HTTParty

  # protect_from_forgery TODO: might want this back

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

  def login_required
    authenticate_user!
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


  def admin_user?
    if current_user
      return current_user.is_admin?
    else
      return false
    end
  end


  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end


end
