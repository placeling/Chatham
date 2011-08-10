require "spec_helper"
require 'json/ext'

describe "API - " do

  describe "GET place for JSON request" do
    it "should return place if it exists" do
      user = Factory.create(:user)
      place = Factory.create(:place)

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      get place_path(:id => place.google_id), {
        :format => 'json'
      }

      response.status.should be(200)

      showPlace = JSON.parse( response.body )
      showPlace['name'].should == place.name

    end

    it "should return place after creating it if it doesn't exist" do
      user = Factory.create(:user)
      place = Factory.build(:place) #build won't persist like create does

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      get place_path(:id => place.google_id), {
        :format => 'json',
        :google_ref => place.google_ref
      }

      response.status.should be(200)

      showPlace = JSON.parse( response.body )
      showPlace['name'].should == place.name
    end
  end

  describe "GET nearby_places for JSON request" do
    it "should do show nearby places for a co-ordinate" do
      get nearby_places_path, {:format => "json",:lat => '-33.8599827', :long =>'151.2021282', :accuracy=>'500'}
      response.status.should be(200)
      response.body.should include("Pylon")

      nearby = JSON.parse( response.body )
      place_found = false
      for place in nearby
        if place['id'] == "e22913360d0b946d099c7a32a77a95e49f9ead66"#Pylon Lookout
          place_found = true
          break
        end
      end

      place_found.should == true
    end

    it "should return distances to places" do
      get nearby_places_path, {:format => "json",:lat => '49.268547', :long =>'-123.15279', :accuracy=>'500'}
      response.status.should be(200)

      nearby = JSON.parse( response.body )

      for place in nearby
        place['distance'].should <= 500
      end

    end
  end

end