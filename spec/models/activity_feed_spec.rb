require 'spec_helper'

describe ActivityFeed do
  it "returns a blank activity created when build_activity called" do
    user = Factory.create(:user)
    activity = user.build_activity

    activity.should be_valid
    activity.save

  end

  it "creates a follow event on user " do
    user = Factory.create(:user)
    user2 = Factory.create(:user)
    user.follow( user2 )

    user.reload #necessary since the activity stuff happens in another environment-ish
    user2.reload

    activity_feed = user.activity_feed

    activity_feed.activities.count.should == 1
    activity = activity_feed.activities.first

    activity.activity_type.should == "FOLLOW"
    activity.actor1.should == user.id
    activity.thumb1.should == user.thumb_url
    activity.actor2.should == user2.id
    activity.username1.should == user.username
    activity.username2.should == user2.username

  end

  it "creates an event on user perspective adding" do
    user = Factory.create(:user)
    place = Factory.create(:place)
    perspective = Factory.create(:perspective, :user => user, :place =>place)

    user.reload #necessary since the activity stuff happens in another environment-ish
    perspective.reload
    place.reload

    activity_feed = user.activity_feed

    activity_feed.activities.count.should == 1
    activity = activity_feed.activities.first

    activity.activity_type.should == "NEW_PERSPECTIVE"
    activity.actor1.should == user.id
    activity.thumb1.should == user.thumb_url
    activity.username1.should == user.username
    activity.subject.should == perspective.id

  end

  it "creates an event on user perspective modifiying" do
    user = Factory.create(:user)
    place = Factory.create(:place)
    perspective = Factory.create(:perspective, :user => user, :place =>place)
    sleep 1

    perspective.memo = "new memo"
    perspective.save

    user.reload #necessary since the activity stuff happens in another environment-ish
    perspective.reload
    place.reload

    activity_feed = user.activity_feed

    activity_feed.activities.count.should == 1 #don't show update within' 1 day
    activity = activity_feed.activities.first

    activity.activity_type.should == "NEW_PERSPECTIVE"
    activity.actor1.should == user.id
    activity.thumb1.should == user.thumb_url
    activity.username1.should == user.username
    activity.subject.should == perspective.id

  end

  it "creates an event on user perspective starring" do
    user = Factory.create(:user)
    user2 = Factory.create(:user)
    place = Factory.create(:place)
    perspective = Factory.create(:perspective, :user => user2, :place =>place)

    user.star( perspective )

    user.reload #necessary since the activity stuff happens in another environment-ish
    user2.reload
    perspective.reload
    place.reload

    activity_feed = user.activity_feed

    activity_feed.activities.count.should == 1
    activity = activity_feed.activities.first

    activity.activity_type.should == "STAR_PERSPECTIVE"
    activity.actor1.should == user.id
    activity.thumb1.should == user.thumb_url
    activity.username1.should == user.username
    activity.actor2.should == user2.id
    activity.username2.should == user2.username
    activity.subject.should == perspective.id

  end



end
