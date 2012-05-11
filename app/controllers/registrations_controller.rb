class RegistrationsController < Devise::RegistrationsController
  after_filter :check_location, :reset_notifications, :only => [:create]
  before_filter :check_timestamp, :only => :create
  before_filter :update_session, :only => :new
  
  #def new
  #  super
  #  session[:"user_return_to"] = URI(request.referer).path unless request.referer.nil? # WILL FAIL ON LINK FROM SIGNIN
  #  puts "here's the session:"
  #  puts session[:"user_return_to"]
  #end
  
  def update_session
    puts "in update_session"
    puts "request.referer is:"
    puts request.referer
    puts "current session[:user_return_to] is:"
    puts session[:"user_return_to"]
    if URI(request.referer).path == "/" || URI(request.referer).path == new_user_session_path
      session[:"user_return_to"] = nil
    else
      session[:"user_return_to"] = request.referer
    end
    #puts session[:"user_return_to"]
    #session[:"user_return_to"] = "/users/imack/recent"
  end
  
  protected
    def after_sign_up_path_for(resource)
      puts "in after_sign_up_path_for"
      puts "here's session[:user_return_to]"
      puts session[:user_return_to]
      if session[:user_return_to] == nil
        user_path(current_user)
      end
      #session[:"user_return_to"] = "/users/imack/recent"
      #puts "referer"
      #puts request.referer
      #puts "session[:user_return_to]"
      #puts session[:"user_return_to"]
      #puts "session[:user.return_to]"
      #puts session[:"user.return_to"]
      #{}"/users/meg/recent"
    end
    
    #def after_inactive_sign_up_path_for(resource)
    #  '/'
    #end
    
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