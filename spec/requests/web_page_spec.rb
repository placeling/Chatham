require "rspec"

describe "Web Page" do

  describe "GET nearby_places for HTML request" do
    it "should do show nearby places for a co-ordinate" do
      get nearby_places_path, {:lat => '-33.8599827', :long =>'151.2021282', :accuracy=>'500'}
      response.status.should be(200)

      response.body.should include("Barangaroo")
    end
  end



end