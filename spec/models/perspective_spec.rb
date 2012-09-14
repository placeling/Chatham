require "spec_helper"
require 'carrierwave/test/matchers'

describe Perspective do
  include CarrierWave::Test::Matchers

  it "should attach a photo" do

    user = Factory.create(:user, :email => 'tyler@placeling.com', :password => 'foofoo')
    perspective = Factory.create(:perspective, :user => user)

    pic = perspective.pictures.build()

    pic.image = File.new(Rails.root + 'spec/fixtures/IMG_0288.JPG')

    pic.save!

    perspective.reload
    perspective.pictures.count.should be(1)
    pic = perspective.pictures.first
    pic.image.thumb.should be_no_larger_than(160, 160)
    pic.creation_environment.should == Rails.env
  end

  it "should return the json strings associated with a photo" do
    user = Factory.create(:user, :email => 'tyler@placeling.com', :password => 'foofoo')
    perspective = Factory.create(:perspective, :user => user)
    pic = Factory.build(:picture)
    perspective.pictures << pic
    perspective.save
    pic.save

    json = pic.as_json()
    picHash = Hashie::Mash.new(json)

    picHash.thumb_url.should_not be(nil)
    picHash.iphone_url.should_not be(nil)
    picHash.main_url.should_not be(nil)
  end

  it "should extracts hashtags" do
    user = Factory.create(:user, :email => 'tyler@placeling.com', :password => 'foofoo')
    perspective = Factory.create(:perspective, :user => user, :memo => "#breakfast is the #best #tag")

    perspective.tags.count.should == 3
    perspective.tags[1].should == "best"
  end

  it "can be found from a starting offset" do
    user = Factory.create(:user)
    perspective = Factory.create(:perspective, :user => user, :memo => "#breakfast")
    sleep(1)
    Factory.create(:perspective, :user => user, :memo => "#lunch")

    perspectives = Perspective.find_recent_for_user(user, 1, 20)

    perspectives.entries.count.should == 1
    perspectives[0].id.should == perspective.id
  end

  it "should keep it's place's attributes as a sub documnet" do
    perspective = Factory.create(:perspective, :memo => "#breakfast")
    perspective.place_stub.name.should == perspective.place.name

  end

  it "should accept a funky url" do
    perspective = Factory.create(:perspective, :url => "http://localhost:3000/~imack/?p=238")
    perspective.should be_valid
  end

  it "should prevent saving duplicate perspective" do
    perspective = Factory.create(:perspective)
    user = perspective.user
    place = perspective.place

    perspective2 = place.perspectives.build
    perspective2.user = user

    perspective2.should_not be_valid
  end

  it "should reject invalid url" do
    perspective = Factory.build(:perspective, :url => "aae3")
    perspective.should_not be_valid
  end

end