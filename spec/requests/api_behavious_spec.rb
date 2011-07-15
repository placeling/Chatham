require "spec_helper"
require 'json/ext'

describe "API" do

  describe "GET nearby_places for HTML request"
  it "should do show nearby places for a co-ordinate" do
    get nearby_places_path, {:x => '-33.8599827', :y =>'151.2021282', :radius=>'500'}
    response.status.should be(200)

    response.body.should include("Barangaroo")
  end

  describe "GET nearby_places for JSON request"
  it "should do show nearby places for a co-ordinate" do
    get nearby_places_path, {:format => "json",:x => '-33.8599827', :y =>'151.2021282', :radius=>'500'}
    response.status.should be(200)
    response.body.should include("Barangaroo")

    nearby = JSON.parse( response.body )
    place_found = false
    for place in nearby
      if place['id'] == "92f1bbd4ecab8e9add032bccee40a57a8dfd42b4"#Barangaroo
        place_found = true
        break
      end
    end

    place_found.should == true


  end


end