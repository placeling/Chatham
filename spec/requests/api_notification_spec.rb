require "spec_helper"

describe "API - " do

  describe "Notifications" do
    before(:each) do
      #this is cool because each environment has its own namespace
      $redis.flushall
    end

    it "should be created for follows" do
      @ian = Factory.create(:user, :username => "imack")
      @lindsay = Factory.create(:user, :username => "lindsay")

      post_via_redirect user_session_path, 'user[login]' => @ian.username, 'user[password]' => @ian.password

      post follow_user_path(@lindsay), {:format => :json}

      response.status.should be(200)

      @lindsay.notifications.count.should == 1
      @lindsay.notifications[0].should_not be_nil
      @lindsay.notifications[0].subject_name.should == @ian.username
      @lindsay.notifications[0].created_at.should_not be_nil
    end


    it "shouldn't send multiple in a row of same follow" do
      @ian = Factory.create(:user, :username => "imack")
      @lindsay = Factory.create(:user, :username => "lindsay")

      post_via_redirect user_session_path, 'user[login]' => @ian.username, 'user[password]' => @ian.password

      post follow_user_path(@lindsay), {:format => :json}
      post unfollow_user_path(@lindsay), {:format => :json}
      post follow_user_path(@lindsay), {:format => :json}

      response.status.should be(200)

      @lindsay.notifications.count.should == 1
      @lindsay.notifications[0].should_not be_nil
      @lindsay.notifications[0].subject_name.should == @ian.username
    end

    it "shouldn't send multiple in a row of same star" do
      @ian = Factory.create(:user, :username => "imack")
      @lindsay = Factory.create(:user, :username => "lindsay")
      perspective = Factory.create(:perspective, :user => @ian)

      post_via_redirect user_session_path, 'user[login]' => @ian.username, 'user[password]' => @ian.password

      post star_perspective_path(perspective), {:format => :json}
      post unstar_perspective_path(perspective), {:format => :json}
      post star_perspective_path(perspective), {:format => :json}

      response.status.should be(200)

      @lindsay.notifications.count.should == 1
      @lindsay.notifications[0].should_not be_nil
      @lindsay.notifications[0].subject_name.should == perspective.place.name
    end


  end
end