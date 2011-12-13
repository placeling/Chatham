class ApplicationController < ActionController::Base
  # protect_from_forgery TODO: might want this back
  before_filter :api_check

  alias :logged_in? :user_signed_in?
  before_filter :log_request


  def log_request
    logger.info("Started #{request.method} #{request.url}")
    for header in request.env.select {|k,v| k.match("^HTTP.*")}
      logger.info("HEADER #{header}")
    end
  end

  def after_sign_in_path_for(resource)
    return (session[:"user.return_to"].nil?) ? "/" : session[:"user.return_to"].to_s
  end
  
  def after_sign_out_path_for(resource)
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

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  #oauth-plugin needs this
  def current_user=(user)
    @current_user = user
  end

end
