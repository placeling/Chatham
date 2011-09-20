require 'spec_helper'
require 'google_places'

describe GooglePlaces do
  before(:each) do
    @gp = GooglePlaces.new
  end
  
  it "shouldn't be able to check in at an invalid location" do
    failed_check_in = @gp.check_in("invalid location")
    
    failed_check_in.should == "Invalid location"
  end
  
  it "shouldn't be able to check in if missing a valid reference" do
    place = Place.new
    place.name = "Fake place"
    place.google_id = "Fake1234"
    place.location = [45.0, 45.0]
    place.venue_types = ["other"]
    place.save
    
    failed_check_in = @gp.check_in("Fake1234")
    
    failed_check_in.should == "No google reference"
  end
  
  it "should not return any political results for location" do
    nearby = @gp.find_nearby(49.268547,-123.15279,500, false)

    extraneous_result = false
    for place in nearby
      if place.types.include?( "political" )
        extraneous_result = true
        break
      end
    end

    extraneous_result.should == false
  end

  it "gets nearby places for a busy co-ordinate" do
    nearby = @gp.find_nearby(-33.8599827,151.2021282,500)

    place_found = false
    for place in nearby
      if place.id == "e22913360d0b946d099c7a32a77a95e49f9ead66" #pylon lookout
        place_found = true
        break
      end
    end

    place_found.should == true
  end

  it "finds a place by name and rough co-ordinates" do
    nearby = @gp.find_nearby(49.268547,-123.15279,500, "Calhoun's")

    place_found = false
    for place in nearby
      if place.id == "227eda8780805995c178f614fbf7aab34090f187"#calhouns
        place_found = true
        break
      end
    end

    place_found.should == true
  end

  it "gets details of a specific place" do
    google_place = @gp.get_place("CnRqAAAAEEnWTAiWPjatj80RAvWUuwVZWXsl25lQ5R_5XHczhyTX0gRT_NXn198gyOfAgK7-mEoWP4lYSSOTUBt5PcyvF8kIb7F8GahGFgFc_t9Z7mOH3pMn0GEaLMoXIFaqCgLCV1j2I4QzPra2vMXu3EjgxBIQomUMMDgY3unvRAVpspfIghoUvERBjeBrR0tfu5x3pQBrmJBb1xU")

    google_place.id.should == "a648ca9b8af31e9726947caecfd062406dc89440"

  end

  it "doesn't work with a bad key" do
    @gp.api_key = "badkey"
    expect{ @gp.find_nearby(-33.8599827,151.2021282,500) }.to raise_error
  end


  it "handles a request in the middle of nowhere" do
    nearby = @gp.find_nearby(48.40003249610685,-144.228515625,500)
    nearby.length.should == 0
  end

  it "searches for a place; if found deletes it, creates/recreates it, confirms it's searchable, checks in and deletes it" do
    growlab = Factory.create(:new_place)
    
    searcher = @gp.find_nearby(growlab.location[0], growlab.location[1], 10, growlab.name)
    
    place_found = false
    for place in searcher
      if place.name == growlab.name
        reference = place.reference
        place_found = true
        break
      end
    end
    
    if place_found == true:
      goner = @gp.delete(reference)
      goner.status.should == "OK"
    end
    
    newbie = @gp.create(growlab.location[0], growlab.location[1], 10, growlab.name, growlab.venue_types[0])
    
    newbie.status.should == "OK"
    newbie.reference.should_not be(nil)
    newbie.id.should_not be(nil)
    
    growlab.google_id = newbie.id
    growlab.google_ref = newbie.reference
    growlab.save
    
    searcher = @gp.find_nearby(growlab.location[0], growlab.location[1], 10, growlab.name)
    
    place_found = false
    for place in searcher
      if place.name == growlab.name
        place_found = true
        break
      end
    end
    
    place_found.should == true
    
    successful_check_in = @gp.check_in(growlab.google_id)
    successful_check_in.should == "OK"
        
    goner = @gp.delete(newbie.reference)
    goner.status.should == "OK"
  end
end