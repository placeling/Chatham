require 'spec_helper'
require 'google_places'

describe PlacesController do
  include Devise::TestHelpers

  describe "GET 'places'" do
    it "should be successful" do
      get :index
      response.should be_success
    end
  end

  describe "GET 'search'" do
    render_views
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = Factory.create(:admin)
      sign_in @user
    end

    it "should be successful" do
      get :search
      response.should be_success
    end
  end


  it "gets nearby places for co-ordinate" do
    GooglePlaces.any_instance.expects(:find_nearby).with(-33.8599827,151.2021282,500.0).once().returns([])
    get :nearby, {:lat => '-33.8599827', :long =>'151.2021282', :accuracy=>'500'}
    response.should be_success
  end

end
