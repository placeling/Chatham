require "spec_helper"
require 'hashie/mash'
require 'JSON'

describe Place do

  it "can be found within a radius" do
    place = Factory.create(:place, :location => [49.2682380,-123.1525990] )
    perspective_one = Factory.create(:perspective, :place =>place)

    results = Place.find_all_near(49.2682380,-123.1525990, 10)
    results.count.should == 1
    results[0].id.should == place.id

  end

  it "excluded when not in radius" do
    place = Factory.create(:place, :location => [49.2682380,-123.1525990] )

    perspective_one = Factory.create(:perspective, :place =>place)

    results = Place.find_all_near(49.2682380,1.1525990, 1)
    results.count.should == 0

  end

  it "aggregates tags from associated perspectives" do
    place = Factory.create(:place)

    perspective_one = Factory.create(:perspective, :place =>place, :memo=>"#breakfast #is #the #best #meal of the #day")
    perspective_two = Factory.create(:perspective, :place =>place, :memo=>"I #am a #fan of #breakfast")

    place.tags.should include("breakfast")

  end

  it "increments its perspective count when a perspective is added" do
    lib_square_perspective = Factory.create(:lib_square_perspective)
    lib_square_perspective.place.perspective_count.should == 1
  end

  it "decrements its perspective count when a perspective is added" do
    lib_square_perspective = Factory.create(:lib_square_perspective)
    lib_square =  lib_square_perspective.place
    lib_square.perspective_count.should == 1

    lib_square_perspective.destroy
    lib_square.perspective_count.should == 0
  end

  it "should show the most n active places" do
    sophies = Factory.create(:place)
    lib_square = Factory.create(:lib_square)
    lib_square_perspective = Factory.create(:lib_square_perspective, :place =>lib_square)

    places = Place.top_places( 1 )
    places.first.name.should == lib_square.name

  end

  # Following marked broken as would otherwise write to Google Places API. Use lib/google_places_spec.rb to test
  it "should be able to create a record from user input", :broken => true do
    place = Place.new_from_user_input(
            :name => "Casa MacKinnon",
            :lat => 49.268547,
            :long => -123.15279
         )
    place.save!
    place.should be_valid

    place = Place.all().first
    place.name.should == "Casa MacKinnon"
    place.place_type.should == "USER_CREATED"
  end

  it "should be able to create a record from a Google places hash" do
    file = File.open(Rails.root.join("spec/fixtures/cosmic_cafe_google_place_detail.json"), 'r')
    json = file.readlines.to_s
    hash = Hashie::Mash.new( JSON.parse(json) ).result

    place = Place.new_from_google_place( hash )
    place.save
    place.should be_valid

    place = Place.all().first
    place.google_id.should == "a648ca9b8af31e9726947caecfd062406dc89440"
    place.place_type.should == "GOOGLE_PLACE"
    place.phone_number.should == "(604) 732-6810"
    place.street_address.should == "2095 West 4th Avenue"

  end

  it "should be able to create a record from a Google places hash without address information" do
    file = File.open(Rails.root.join("spec/fixtures/usermade_growlab_google_place_detail.json"), 'r')
    json = file.readlines.to_s
    hash = Hashie::Mash.new( JSON.parse(json) ).result
    
    #puts hash
    
    place = Place.new_from_google_place( hash )
    
    #puts "place.venue_types is in spec is:"
    #puts place.venue_types
    
    place.save
    place.should be_valid

    place = Place.all().first
    place.google_id.should == "a6ccd2c4d6822652e72209c9113dca26dc790ec5"
    place.place_type.should == "GOOGLE_PLACE"

  end
end