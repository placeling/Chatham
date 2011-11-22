require "spec_helper"

describe User do

  it "should show the most n active users" do
    bob = Factory.create(:user, :username => 'bill', :email => "billbob@null.com")
    lib_square_perspective = Factory.create(:lib_square_perspective, :user => bob)

    users = User.top_users( 1 )
    users.first.username.should == bob.username

  end

  it "should add a follower to a user" do
    ian = Factory.create(:user, :username => 'imack')
    lindsay = Factory.create(:user, :username => 'lindsay')
    ian.follow( lindsay )
    ian.save

    lindsay.followers.should include(ian)
    ian.following.should include(lindsay)
    lindsay.following.should_not include(ian)
    ian.followers.should_not include(lindsay)
  end

  it "should be able to unfollow another user" do
    ian = Factory.create(:user, :username => 'imack')
    lindsay = Factory.create(:user, :username => 'lindsay')
    ian.follow( lindsay )
    ian.save

    ian.unfollow( lindsay )

    lindsay.followers.should_not include(ian)
    ian.following.should_not include(lindsay)

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

end