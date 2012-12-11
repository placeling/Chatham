require 'spec_helper'
require 'google_reverse_geocode'

describe GoogleReverseGeocode do
  before(:each) do
    @grg = GoogleReverseGeocode.new
  end

  it "should find a result here" do
    address = @grg.reverse_geocode(49.28345, -123.10998) # 320 W Cordova St

    street_number = nil
    address.address_components.each do |component|
      if component["types"].include? "street_number"
        street_number = component["long_name"]
      end
    end

    street_number.should == "309"
  end

  it "should not find a result here" do
    address = @grg.reverse_geocode(49.391, -123.095) # Backcountry near Grouse Moutain

    address.should == nil
  end
end