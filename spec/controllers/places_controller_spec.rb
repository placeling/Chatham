require 'spec_helper'
require 'google_places'

describe PlacesController do

  describe "GET 'places'" do
    it "should be successful" do
      get :index
      response.should be_success
    end
  end


  it "gets nearby places for co-ordinate" do
    GooglePlaces.any_instance.expects(:find_nearby).with(-33.8599827,151.2021282,500.0).once().returns([])
    get :nearby_places, {:x => '-33.8599827', :y =>'151.2021282', :radius=>'500'}
    response.should be_success
  end

end
