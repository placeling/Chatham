class RegistrationsController < Devise::RegistrationsController
  after_filter :check_location, :only => [:create]

  protected
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