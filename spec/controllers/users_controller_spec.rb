require 'spec_helper'

describe UsersController do

   describe "GET suggested" do
      it "returns list of suggested users" do
        maven = Factory.create(:maven, :username => "gladwell",:location =>[49, -121])
        user = Factory.create(:user, :location =>nil)

        get :suggested, :lat => 49, :long => -120, :format=>:json
        response.should be_success
        users = JSON.parse( response.body )

        users[0]['username'].should == "gladwell"
      end
   end

  describe "GET /:id" do
    describe "with valid params" do
      it "returns imack's profile" do
        user = User.new
        user.username = "imack"

        User.stubs(:where).with(anything).returns([user])
        get :show, :id => user.username
        response.should be_success
      end

    end

    describe "with invalid params" do
      it "returns a 404" do
        expect{get :profile, :username => "t"}.to raise_error(ActionController::RoutingError)
      end
    end
  end

  it "shows a list of users" do
    get :index
    response.should be_success
  end

end
