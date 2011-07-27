class ApplicationController < ActionController::Base
  # protect_from_forgery TODO: might want this back
  before_filter :api_check

  def api_check
    if params[:api_call]
      oauth_required
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

  #oauth-plugin needs this
  def current_user=(user)
    current_user = user
  end

end
