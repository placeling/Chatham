require "spec_helper"

describe User do

  it "should show the most n active users" do
    bob = Factory.create(:user, :username => 'bill', :email => "billbob@null.com")
    lib_square_perspective = Factory.create(:lib_square_perspective)
    tyler = lib_square_perspective.user

    users = User.top_users( 1 )
    users.first.username.should == tyler.username

  end
end