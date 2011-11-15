require "rspec"

describe "Web Page" do

  describe "GET nearby_places for HTML request" do
    it "should do show nearby places for a co-ordinate" do
      get nearby_places_path, {:lat => '49.268547', :long =>'-123.15279', :accuracy=>'500'}
      response.status.should be(200)

      response.body.should include("Sophie")
    end
  end



end