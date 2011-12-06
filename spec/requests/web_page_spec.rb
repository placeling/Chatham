require "spec_helper"

describe "Web Page" do

  # we don't actually have a "nearby" for web yet
  #describe "GET nearby_places for HTML request" do
  #  it "should do show nearby places for a co-ordinate" do
  #    get nearby_places_path, {:lat => '49.268547', :long =>'-123.15279', :accuracy=>'500'}
  #    response.status.should be(200)

  #    response.body.should include("Sophie")
  #  end
  #end

    describe "GET place for HTML request" do
      it "should return a 404 for non-existent page" do
        @place = Factory.build(:place) #notice the build and not a create
        lambda {
          get place_path(@path)
        }.should raise_error(ActionController::RoutingError)
      end
    end


end