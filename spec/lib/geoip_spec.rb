require "spec_helper"

describe "GeoIP" do

  it "should turn an IP into a lat/long" do
    g = GeoIP.new("#{Rails.root}/config/GeoIPcity.dat")
    c = g.city('216.251.139.90')
    c.city_name.should == "Vancouver"
    c.latitude.should be_within(0.5).of(49.25)
    c.longitude.should be_within(0.5).of(-123.1333)

  end
end