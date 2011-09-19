require "spec_helper"
require 'carrierwave/test/matchers'

describe PictureUploader do
  include CarrierWave::Test::Matchers

  before do
    PictureUploader.enable_processing = true
    @perspective = Factory.create(:perspective)
    @picture = @perspective.pictures.build()
    @uploader = PictureUploader.new(@picture, :image)
    @uploader.store!( File.open( Rails.root.join( "spec/fixtures/IMG_0288.JPG" ) ) )
  end

  after do
    PictureUploader.enable_processing = false
  end

  context 'the thumb version' do
    it "should scale down an image to no more than 160 by 160 pixels" do
      @uploader.thumb.should be_no_larger_than(160, 160)
    end
  end

  context 'the iphone  version' do
    it "should scale down an image to fit on an iphone display pixels" do
      @uploader.thumb.should be_no_larger_than(480, 480)
    end
  end

  context 'the main version' do
    it "should scale down an image to fit on an iphone display pixels" do
      @uploader.thumb.should be_no_larger_than(960, 960)
    end
  end

  it "should not be resized" do
    @uploader.should have_dimensions(1536,2048)
  end

end