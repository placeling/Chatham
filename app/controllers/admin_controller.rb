class AdminController < ApplicationController

  before_filter :admin_required, :only => [:dashboard]

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

  def contact_us
  end

  def status
    render :status, :layout =>false
  end

  def dashboard
    @user_count = User.count
    @users = User.descending(:created_at).limit(200)
    @past_day_bookmarks = Perspective.where(:created_at.gt =>1.day.ago)

  end

end
