require "spec_helper"
require 'json/ext'

describe "API - " do

  describe "Place perspectives" do
    it "can all be shown" do
      user = Factory.create(:user)
      user2 = Factory.create(:user)
      user3 = Factory.create(:user)
      place = Factory.create(:place)
      perspective = Factory.create(:perspective, :place =>place, :user =>user2)
      perspective2 = Factory.create(:perspective, :place =>place, :user =>user3)

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password


      get all_place_perspectives_path(place), {
        :format => 'json'
      }

      response.status.should be(200)

      showPlace = JSON.parse( response.body )
      showPlace['perspectives'].count.should == 2
    end

    it "can be shown for users being followed" do
      user = Factory.create(:user)
      user2 = Factory.create(:user)
      user3 = Factory.create(:user)
      place = Factory.create(:place)
      perspective = Factory.create(:perspective, :memo=>"TEST1", :place =>place, :user =>user2)
      perspective2 = Factory.create(:perspective, :memo=>"TEST2", :place =>place, :user =>user3)
      user.follow( user2 )

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password


      get following_place_perspectives_path(place), {
        :format => 'json'
      }

      response.status.should be(200)

      showPlace = JSON.parse( response.body )
      showPlace['perspectives'].count.should == 1
      showPlace['perspectives'][0]['memo'].should == "TEST1"
    end

  end


  describe "GET place for JSON request" do

    it "should return random place if requested" do
      user = Factory.create(:user)
      place = Factory.create(:place)
      perspective = Factory.create(:perspective, :place =>place)

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      get random_places_path, {
        :format => 'json',:lat => '49.8599827', :long =>'-129.2021282'
      }

      response.status.should be(200)

      showPlace = JSON.parse( response.body )
      showPlace['name'].should == place.name

    end

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

    it "should return an existing place with creator and relationship information" do
      user = Factory.create(:user)
      place = Factory.create(:place)
      perspective = Factory.create(:perspective, :user =>user, :place =>place) #triggers a bookmark

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      get place_path(:id => place.google_id), {
        :format => 'json'
      }

      response.status.should be(200)

      showPlace = JSON.parse( response.body )
      showPlace['bookmarked'].should_not be(nil)
      showPlace['bookmarked'].should be(true)
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
      for place in nearby['places']
        if place['id'] == "e22913360d0b946d099c7a32a77a95e49f9ead66"#Pylon Lookout
          place_found = true
          break
        end
      end

      place_found.should == true
    end


    it "should take a search term" do
      get nearby_places_path, {:format => "json",:lat => '49.268547', :long =>'-123.15279', :query => "calhoun's", :accuracy=>'500'}
      response.status.should be(200)

      nearby = JSON.parse( response.body )

      place_found = false
      for place in nearby['places']
        if place['id'] == "227eda8780805995c178f614fbf7aab34090f187"#calhouns
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

      for place in nearby['places']
        place['distance'].should <= 500
      end

    end
  end

end