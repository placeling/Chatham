require "spec_helper"
require "cityname_finder"

describe "CitynameFinder" do

  it "should return human readable location based on lat/long for Vancouver" do
    city_name = CitynameFinder.getCity( 49.2642380,-123.1625990 ) #vancouver
    city_name.should == "Vancouver, BC, Canada"
  end

  it "should return human readable location based on lat/long for Whitby" do
    city_name = CitynameFinder.getCity( 43.887872,-78.953416 ) #whitby
    city_name.should == "Whitby, ON, Canada"
  end

  it "should return human readable location based on lat/long for Sydney, Australia" do
    city_name = CitynameFinder.getCity( -33.894215,151.179771 ) #Sydney
    city_name.should == "Newtown, NSW, Australia"
  end

  it "should return human readable location based on lat/long for Palo Alto" do
    city_name = CitynameFinder.getCity( 37.416936,-122.122135 ) #Palo alto
    city_name.should == "Palo Alto, CA, United States"
  end

  it "shouldn't break on an invalid lat/long" do
    city_name = CitynameFinder.getCity( 0,0 ) #Palo alto
    city_name.should == ""
  end


end