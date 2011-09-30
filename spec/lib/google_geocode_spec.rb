require 'spec_helper'
require 'google_geocode'

describe GoogleGeocode do
  before(:each) do
    @gg = GoogleGeocode.new
  end

  it "should find a result here" do
    result = @gg.geocode(["1600 Amphitheatre Parkway","Mountain View","CA"]) # Google HQ
    
    lat = result.geometry.location.lat.nil?
    lng = result.geometry.location.lng.nil?
    
    lat.should == false
    lng.should == false
  end

  it "should not find a result here" do
    result = @gg.geocode(["A fake address","wrapped up in another one"])
    
    result.should == nil
  end
end