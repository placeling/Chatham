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

  def home_timeline
    start_pos = params[:start].to_i
    count = 20

    @activities = current_user.feed(start_pos, count)

    respond_to do |format|
      format.json { render :json => {:home_feed => @activities.as_json(), :user => current_user.as_json()} }
      format.html
    end

  end

  def escape_pod


  end


end
