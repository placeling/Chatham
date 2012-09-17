require "spec_helper"

describe User do

  it "should show the most n active users" do
    bob = Factory.create(:user, :username => 'bill', :email => "billbob@null.com")
    lib_square_perspective = Factory.create(:lib_square_perspective, :user => bob)

    users = User.top_users(1)
    users.first.username.should == bob.username

  end

  it "should add a follower to a user" do
    ian = Factory.create(:user, :username => 'imack')
    lindsay = Factory.create(:user, :username => 'lindsay')
    ian.follow(lindsay)
    ian.save

    lindsay.followers.should include(ian)
    ian.following.should include(lindsay)
    lindsay.following.should_not include(ian)
    ian.followers.should_not include(lindsay)
  end

  it "should be able to unfollow another user" do
    ian = Factory.create(:user, :username => 'imack')
    lindsay = Factory.create(:user, :username => 'lindsay')

    ian.follow(lindsay)

    ian.reload
    lindsay.reload

    lindsay.followers.should include(ian)
    ian.following.should include(lindsay)

    ian.unfollow(lindsay)

    ian.reload
    lindsay.reload

    ian.following.should_not include(lindsay)
    lindsay.followers.should_not include(ian)

    lindsay = User.find(lindsay.id) #make sure was unfollowed, not deleted
    lindsay.should be_valid
  end

  it "should not be able to be created with inappropriate username" do
    user = Factory.build(:user, :username => 'bitch')
    user.should_not be_valid
  end

  it "should not be able to be created with reserved username" do
    user = Factory.build(:user, :username => 'places')
    user.should_not be_valid
  end

  it "should not be able to be created with a shitty password" do
    user = Factory.build(:user, :password => 'abc123')
    user.should_not be_valid
  end

  it "can be searched for" do
    user1 = Factory.create(:user, :username => 'tyler')
    user2 = Factory.create(:user, :username => 'ian')
    user3 = Factory.create(:user, :username => 'lindsay')

    users = User.search_by_username("ty")
    users.count.should == 1
    users[0].id.should == user1.id

    users = User.search_by_username("z")
    users.count.should == 0

    users = User.search_by_username("tyler")
    users.count.should == 1
    users[0].id.should == user1.id

  end

  it "has User settings" do
    user = Factory.create(:user)
    user.user_settings.should_not be(nil)
  end

  it "can be have account deleted with all associated stuff" do
    ruser = Factory.create(:user, :username => "tyler")

    place = Factory.create(:place) #have to create so properly persisted
    user = Factory.create(:user)
    user2 = Factory.create(:user)
    ca = Factory.create(:client_application, :name => "Agree2")
    question = Factory.create(:question, :user => user)

    request_token = ca.create_request_token
    request_token.authorize!(user)
    request_token.provided_oauth_verifier = request_token.verifier
    access_token = request_token.exchange!

    OauthToken.count.should == 2

    perspective1 = Factory.create(:perspective, :user => user, :place => place)
    perspective3 = Factory.create(:perspective, :user => user2, :place => place, :memo => "SHIZZLE") #for commenting on

    user.star(perspective3)
    perspective3.save!

    user2.follow(user)
    user.save!
    user2.save!

    user.reload
    user2.reload

    user.follow(user2)
    user2.save
    user.save

    user.followers.count.should == 1
    user2.followers.count.should == 1
    Question.count.should == 1

    @placemark_comment = perspective3.placemark_comments.build({:comment => "blah blah blah"})
    @placemark_comment.user = user
    @placemark_comment.save!

    perspective3.reload
    perspective3.placemark_comments.count.should == 1

    user.destroy
    perspective3.reload

    Perspective.count.should == 1
    User.count.should == 2
    Question.count.should == 1
    Question.first.user.username.should == ruser.username
    user2.followers.count.should == 0
    perspective3.placemark_comments.count.should == 0

  end


  it "can't be created with duplicate username or email'" do
    user = Factory.create(:user, :username => "test", :email => "test@placeling.com")
    user2 = Factory.build(:user, :username => "test")

    user2.save.should == false
    user2.errors.count.should == 1

    user3 = Factory.build(:user, :email => "test@placeling.com")
    user3.save.should == false
    user3.errors.count.should >= 1

    User.count.should == 1
  end

end