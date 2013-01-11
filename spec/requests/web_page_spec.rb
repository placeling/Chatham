require "spec_helper"

describe "Web App" do

  it "should render homepage without any JS errors", js: true do
    visit "/"
  end

  it "should return a 404 for non-existent page" do
    @place = Factory.build(:place) #notice the build and not a create
    lambda {
      get place_path(@path)
    }.should raise_error(ActionController::RoutingError)
  end
end