class AdminController < ApplicationController

  before_filter :admin_required, :only => [:dashboard, :blog_stats, :firehose, :flagged_place, :update_place]

  def app

    respond_to do |format|
      format.html { redirect_to "http://itunes.apple.com/ca/app/placeling/id465502398?ls=1&mt=8" }
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
      format.json { render :file => "#{Rails.root}/config/google_place_mapping.json" }
    end
  end

  def map
    respond_to do |format|
      format.html
    end
  end

  def share
    respond_to do |format|
      format.html
    end
  end

  def guide
    respond_to do |format|
      format.html
    end
  end

  def investors

  end

  def heartbeat
    render :status, :layout => false
  end

  def dashboard
    @user_count = User.count
    @users = User.descending(:created_at).limit(200)
    @past_day_bookmarks = Perspective.where(:created_at.gt => 1.day.ago)

  end

  def flagged_place
    gp = GooglePlaces.new

    @place = Place.where(:update_flag => true).first
    @updatedPlace = gp.get_place(@place.google_ref, false)
    @merge_place = Place.find_by_google_id(@updatedPlace.id) unless @updatedPlace.nil?

    if @updatedPlace.geometry.nil?
      @updatedPlace = nil
    end

    if @merge_place.nil? || @merge_place.id == @place.id
      @merge_place = nil
    end

    respond_to do |format|
      format.html
    end
  end

  def update_place
    gp = GooglePlaces.new
    @place = Place.find(params[:pid])

    if params[:opt] == "update"
      @updatedPlace = gp.get_place(@place.google_ref, false)
      @place = @place.update_from_google_place(@updatedPlace)
      @place.update_flag = false
      @place.save!
    elsif params[:opt] == "skip"
      @place.update_flag = false
      @place.save!
    elsif params[:opt] == "merge"
      @updatedPlace = gp.get_place(@place.google_ref, false)
      @place = @place.update_from_google_place(@updatedPlace)
      @merge_place = Place.find_by_google_id(@updatedPlace.id)

      if @updatedPlace.geometry.nil?
        @updatedPlace = nil
      end

      questions = Question.any_of({'answers.place_id' => @merge_place.id})

      questions.each do |question|
        question.answers.each do |answer|
          if answer.place.id == @merge_place.id
            answer.place = @place
            answer.save
          end
        end
      end

      @merge_place.perspectives.each do |perspective|
        perspective.place = @place
        @place.perspective_count += 1

        if perspective.user.highlighted_places.include? @merge_place.id
          perspective.user.highlighted_places << @place.id
          perspective.user.save!
        end
        perspective.save!

      end
      @merge_place.destroy

      @place.update_flag = false
      @place.save!
    end

    respond_to do |format|
      format.html { redirect_to :action => "flagged_place" }
    end
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
      @activities = @activities.collect { |r| Activity.decode(r) }
    else
      @activities
    end

  end

end
