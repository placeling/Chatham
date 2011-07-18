class ApplicationController < ActionController::Base
  before_filter :fix_location_parameters
  protect_from_forgery

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

  def fix_location_parameters
    if params[:location]
      location = params[:location]
      if location[0].is_a? String
        location[0] = location[0].to_f
      end
      if location[1].is_a? String
        location[1] = location[1].to_f
      end
    end

  end

end
