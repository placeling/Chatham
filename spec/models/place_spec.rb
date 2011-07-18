require "spec_helper"
require 'hashie/mash'
require 'JSON'

describe Place do

  it "should be able to create a record from user input" do
    place = Place.new_from_user_input(
            :name => "Casa MacKinnon",
            :location => [49.268547,-123.15279]
         )
    place.save
    place.should be_valid

    place = Place.all().first
    place.name.should == "Casa MacKinnon"
    place.place_type.should == "USER_CREATED"
  end

  it "should be able to create a record from a Google places hash" do
    file = File.open("../fixtures/cosmic_cafe_google_place_detail.json", 'r')
    json = file.readlines.to_s
    hash = Hashie::Mash.new( JSON.parse(json) ).result

    place = Place.new_from_google_place( hash )
    place.save
    place.should be_valid

    place = Place.all().first
    place.google_id.should == "a648ca9b8af31e9726947caecfd062406dc89440"
    place.place_type.should == "GOOGLE_PLACE"

  end
end