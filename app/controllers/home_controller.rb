class HomeController < ApplicationController
  before_filter :login_required, :only => [:home_timeline, :logged_in_home, :escape_pod]

  def logged_out_home

    respond_to do |format|
      format.html
    end
  end

  def index
    logged_out_home
  end


  def escape_pod


  end

  def error503

    render :view => "home/error503", status: 503, :format => :html

  end


end
