class AdminController < ApplicationController

  before_filter :admin_required, :only => [:dashboard, :blog_stats, :firehose]

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

  def bloggers
    respond_to do |format|
      format.html
    end
  end

  def categories
    respond_to do |format|
      format.json  {render :file =>"#{Rails.root}/config/google_place_mapping.json"}
    end
  end
  
  def map
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

  def blog_stats

    ca = ClientApplication.find('4f298a1057b4e33324000003')
    @perspectives = ca.perspectives.descending(:created_at).limit(200)

  end

  def firehose
      # get latest feed using reverse range lookup of sorted set
  # then decode raw JSON back into Ruby objects
    @activities=$redis.zrevrange "FIREHOSEFEED", 0, 50
    if @activities.size > 0
      @activities = @activities.collect {|r| Activity.decode(r)}
    else
      @activities
    end

  end

end
