require "rspec"

describe "Web Page" do

  describe "GET nearby_places for HTML request" do
    it "should do show nearby places for a co-ordinate" do
      get nearby_places_path, {:lat => '-33.860084', :long =>'151.207198', :accuracy=>'500'}
      response.status.should be(200)

      response.body.should include("Pylon")
    end
  end



end