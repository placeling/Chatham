require 'spec_helper'

describe UsersController do

   describe "GET suggested" do
      it "returns list of suggested users" do
        maven = Factory.create(:maven, :username => "gladwell",:location =>[49, -121])

        get :suggested, :lat => 49, :long => -120, :format=>:json
        response.should be_success
        users = JSON.parse( response.body )

        users['suggested'][0]['username'].should == "gladwell"
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

      it "returns returns follower and followee count in json" do
        user = Factory.create(:user, :username=>"imack")
        user2 = Factory.create(:user, :username=>"lindsay")

        user.follow( user2 )

        get :show, :id => user.username, :format=>:json

        response.should be_success

        user = JSON.parse( response.body )

        PP.pp user
        user['follower_count'].should == 0
        user['following_count'].should == 1

      end

      it "returns relationship information" do
        user = Factory.create(:user, :username=>"imack")
        user2 = Factory.create(:user, :username=>"lindsay")

        user.follow( user2 )

        sign_in user

        get :show, :id => user2.username, :format=>:json

        response.should be_success

        user = JSON.parse( response.body )

        PP.pp user
        user['following'].should == true
        user['follows_you'].should == false

      end

    end

    describe "with invalid params" do
      it "returns a 404" do
        expect{get :profile, :username => "t"}.to raise_error(ActionController::RoutingError)
      end
    end
  end


end
