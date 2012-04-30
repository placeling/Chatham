class RegistrationsController < Devise::RegistrationsController
  after_filter :check_location, :reset_notifications, :only => [:create]

  protected
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
        if location["remote_ip"]
          current_user.location =  [ location["remote_ip"]["lat"], location["remote_ip"]["lng"] ]
          current_user.save
        end
      end
    end
end