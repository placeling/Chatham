class RegistrationsController < Devise::RegistrationsController
  after_filter :check_location, :reset_notifications, :track_signup, :only => [:create]
  before_filter :check_timestamp, :only => :create
  before_filter :update_session, :only => :new

  # REALLY IMPORTANT COMMENT
  # To understand all the logic below, you need to know something about Devise:
  # If it find a value in session[:"user_return_to"] it never calls after_sign_up_path_for(resource)

  def update_session
    # If user is coming from home page, we want them to go to their map
    if (request.referer && URI(request.referer).path == "/")
      session[:"user_return_to"] = nil
      # If user clicked to sign in page and then register, clear session if originally from homepage
    elsif request.referer && URI(request.referer).path == new_user_session_path && session[:"user_return_to"] == "/"
      session[:"user_return_to"] = nil
    else
      session[:"user_return_to"] = request.referer
    end
  end

  def track_signup

  end

  protected
  def after_sign_up_path_for(resource)
    if session[:user_return_to] == nil
      user_path(current_user)
    end
  end

  def check_timestamp
    timestamp = params['page_timestamp'].to_i
    diff = timestamp - Time.now.to_i
    if diff.abs < 4 || params['page_timestamp'].nil?
      flash[:notice] = "You filled out that form pretty fast, so we think you might be a bot, try again"
      redirect_to new_user_registration_path
      return false
    end
  end

  def reset_notifications
    if current_user
      #setup for non-iphone version
      current_user.user_settings.new_follower_notify = false
      current_user.user_settings.remark_notify = false

      current_user.user_settings.new_follower_email = true
      current_user.user_settings.remark_email =true
      current_user.save
    end
  end

  def check_location
    if current_user && current_user.location.nil?
      loc = get_location
      if loc && loc["remote_ip"]
        current_user.location = [loc["remote_ip"]["lat"], loc["remote_ip"]["lng"]]
        current_user.save
      end
    end
  end

end