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
      pic.image.thumb.should be_no_larger_than(64, 64)
  end
end