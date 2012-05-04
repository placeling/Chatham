class RegistrationsController < Devise::RegistrationsController
  after_filter :check_location, :reset_notifications, :only => [:create]
  before_filter :check_timestamp, :only => :create

  protected
    def check_timestamp
      timestamp = params['page_timestamp'].to_i
      diff = timestamp - Time.now.to_i
      if diff.abs < 2
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
          current_user.location =  [ loc["remote_ip"]["lat"], loc["remote_ip"]["lng"] ]
          current_user.save
        end
      end
    end
end