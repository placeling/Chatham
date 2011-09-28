require "spec_helper"
require 'carrierwave/test/matchers'

describe Perspective do
  include CarrierWave::Test::Matchers

  it "should attach a photo" do

      user = Factory.create(:user, :email=>'tyler@placeling.com', :password=>'foofoo')
      perspective = Factory.create(:perspective, :user =>user)

      pic = perspective.pictures.build()

      pic.image = File.new(Rails.root + 'spec/fixtures/IMG_0288.JPG')

      pic.save!

      perspective = Perspective.find( perspective.id )
      perspective.pictures.count.should be(1)
      pic = perspective.pictures.first
      pic.image.thumb.should be_no_larger_than(160, 160)
      pic.creation_environment.should == Rails.env
  end

  it "should return the json strings associated with a photo" do

      user = Factory.create(:user, :email=>'tyler@placeling.com', :password=>'foofoo')
      perspective = Factory.create(:perspective, :user =>user)
      pic = Factory.build(:picture)
      perspective.pictures << pic
      perspective.save
      pic.save

      json = pic.as_json()
      picHash = Hashie::Mash.new( json )

      picHash.thumb_url.should_not be(nil)
      picHash.iphone_url.should_not be(nil)
      picHash.main_url.should_not be(nil)
  end

  it "should extracts hashtags" do
    user = Factory.create(:user, :email=>'tyler@placeling.com', :password=>'foofoo')
    perspective = Factory.create(:perspective, :user =>user, :memo => "#breakfast is the #best #tag")

    perspective.tags.count.should == 3
    perspective.tags[1].should == "best"
  end
end