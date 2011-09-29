class HomeController < ApplicationController
  before_filter :login_required, :only =>[:home_timeline]

  def index

    @top_users = User.top_users(10)
    @top_places = Place.top_places(10)
  end

  def home_timeline

    @activities = []
    #this is generally expensive, but fine for now.

    for user in current_user.following
      if user.activity_feed
        head = user.activity_feed.head_chunk
        @activities =  @activities + head.activities
        if !head.next.nil?
          @activities =  @activities + head.next.activities
        end
      end
    end

    if current_user.activity_feed
       @activities = @activities + current_user.activity_feed.activities
    end

    @activities.sort! { |a,b| a.created_at <=> b.created_at }
    @activities.reverse!

    respond_to do |format|
      format.json { render :json => {:home_feed => @activities.as_json() } }
      format.html
    end

  end

end
