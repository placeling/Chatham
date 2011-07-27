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
    ian.followees.should include(lindsay)
    lindsay.followees.should_not include(ian)
    ian.followers.should_not include(lindsay)
  end

  it "should be able to unfollow another user" do
    ian = Factory.create(:user, :username => 'imack')
    lindsay = Factory.create(:user, :username => 'lindsay')
    ian.follow( lindsay )
    ian.save

    ian.unfollow( lindsay )

    lindsay.followers.should_not include(ian)
    ian.followees.should_not include(lindsay)
  end

end