require 'spec_helper'
require 'google_places'

describe GooglePlaces do
  before(:each) do
    @gp = GooglePlaces.new
  end

  it "gets nearby places for a busy co-ordinate" do
    nearby = @gp.find_nearby(-33.8599827,151.2021282,500)

    place_found = false
    for place in nearby
      if place.id == "92f1bbd4ecab8e9add032bccee40a57a8dfd42b4"#Barangaroo
        place_found = true
        break
      end
    end

    place_found.should == true
  end


  it "doesn't work with a bad key" do
    @gp.api_key = "badkey"
    expect{ @gp.find_nearby(-33.8599827,151.2021282,500) }.to raise_error
  end


  it "handles a request in the middle of nowhere" do
    nearby = @gp.find_nearby(48.40003249610685,-144.228515625,500)
    nearby.length.should == 0
  end


end