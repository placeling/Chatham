class SessionsController < Devise::SessionsController
  before_filter :set_return_path, :only => [:new]
  
  def set_return_path
    if session[:"user_return_to"].nil?
      session[:"user_return_to"] = URI(request.referer).path
    end
  end
end
