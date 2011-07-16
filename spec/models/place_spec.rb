require "spec_helper"
require 'hashie/mash'
require 'JSON'

describe Place do

  it "should be able to create a record from a Google places hash" do
    file = File.open("../fixtures/cosmic_cafe_google_place_detail.json", 'r')
    json = file.readlines.to_s
    hash = Hashie::Mash.new( JSON.parse(json) ).result

    place = Place.create_from_google_place( hash )
    place.should be_valid
    place.google_id.should == "a648ca9b8af31e9726947caecfd062406dc89440"
  end
end