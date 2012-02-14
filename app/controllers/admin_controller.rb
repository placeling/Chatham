class AdminController < ApplicationController

  before_filter :admin_required, :only => [:dashboard]

  def app
    track! :app_store
    respond_to do |format|
      format.html{ redirect_to "http://itunes.apple.com/ca/app/placeling/id465502398?ls=1&mt=8" }
    end
  end

  def terms_of_service
    @terms = t("tos")
    respond_to do |format|
      format.json { render :json => {:terms => @terms} }
      format.html
    end
  end

  def privacy_policy
    @privacy = t("privacy")
    respond_to do |format|
      format.json { render :json => {:privacy => @privacy} }
      format.html
    end
  end

  def about_us
    @ian = User.where(:username => "imack").first()
    @lindsay = User.where(:username => "lindsayrgwatt").first()
    @about_us = t("about_us")
    respond_to do |format|
      format.html
    end
  end

  def investors

  end

  def heartbeat
    render :status, :layout =>false
  end

  def dashboard
    @user_count = User.count
    @users = User.descending(:created_at).limit(200)
    @past_day_bookmarks = Perspective.where(:created_at.gt =>1.day.ago)

  end

end
