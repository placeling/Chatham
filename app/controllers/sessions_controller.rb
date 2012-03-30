class SessionsController < Devise::SessionsController
  before_filter :set_return_path, :only => [:new]
  
  def set_return_path
    puts "Just got called"
    puts URI(request.referer).path
    session[:"user.return_to"] = URI(request.referer).path
  end
end
