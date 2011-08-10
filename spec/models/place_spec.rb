require "spec_helper"
require 'hashie/mash'
require 'JSON'

describe Place do

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

  it "should be able to create a record from user input" do
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
end