require 'spec_helper'

describe UsersController do


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
