require "spec_helper"
require 'json/ext'

describe "API - " do

  describe "perspective can be added" do
    it "to a new place that exists on Google Places" do
      # 49.268547,-123.15279 - Ian's House

      user = Factory.create(:user, :email=>'tyler@placeling.com', :password=>'foofoo')

      post_via_redirect user_session_path, 'user[email]' => user.email, 'user[password]' => user.password

      post_via_redirect perspectives_path, {
        :format => 'json',
        :google_ref=> 'CnRqAAAAENm_o7U-bsSFgVriK3TWgSX04_dXx9_LQx52SEEe77eIWhU8hrJUI9p8UCP-uyzcUMPPEJDu9WjdRR9Sl3Y5-_FBd-Mr1c6x4DocgErDdRMr3nykG7r1_SC4gBBH9amVAcpJvP80bN8LD94leLBpkRIQmP_0UC128e_Co4mg1H9vEhoU960SUeBMRddoH6mTUgUpm6op838',
        :google_id=>"a648ca9b8af31e9726947caecfd062406dc89440",
        :perspective => {
            :memo => "This place is da bomb",
            :location => {
              :x => '49.268547',
              :y =>'-123.15279'
            },
            :radius=>'500'
        }
      }
      response.status.should be(200)
      response.body.should include("da bomb")
    end
  end


  describe "GET nearby_places for HTML request" do
    it "should do show nearby places for a co-ordinate" do
      get nearby_places_path, {:x => '-33.8599827', :y =>'151.2021282', :radius=>'500'}
      response.status.should be(200)

      response.body.should include("Barangaroo")
    end
  end

  describe "GET nearby_places for JSON request" do
    it "should do show nearby places for a co-ordinate" do
      get nearby_places_path, {:format => "json",:x => '-33.8599827', :y =>'151.2021282', :radius=>'500'}
      response.status.should be(200)
      response.body.should include("Barangaroo")

      nearby = JSON.parse( response.body )
      place_found = false
      for place in nearby
        if place['id'] == "92f1bbd4ecab8e9add032bccee40a57a8dfd42b4"#Barangaroo
          place_found = true
          break
        end
      end

      place_found.should == true
    end
  end

end