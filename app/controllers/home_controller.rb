class HomeController < ApplicationController
  before_filter :login_required, :only => [:escape_pod, :download]

  def index
    respond_to do |format|
      format.html
    end
  end


  def escape_pod

    if current_user.escape_pod && File.exists?( "public/uploads/#{current_user.username}_placeling.zip")
      send_file "public/uploads/#{current_user.username}_placeling.zip"
    else
      current_user.want_email = true
      current_user.save

      redirect_to '/',  notice: "Your data is still processing, we'll email you when its ready"
    end
  end

  def error503

    render file: "#{Rails.root}/public/503.html", status: 503, :format => :html

  end


end
