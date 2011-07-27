require "spec_helper"
require 'json/ext'

describe "API - " do

  describe "bookmarks for a user can listed" do
    before(:each) do

      @perspective = Factory.create(:perspective, :memo =>"COSMIC")
      @user = @perspective.user
      sleep 1 #ensured a different created_at
      @perspective2 = Factory.create(:lib_square_perspective, :memo =>"LIB SQUARE", :user => @user)

    end

    it "by reverse creation date (default)" do

      get user_perspectives_path(@user), {:format => :json}
      response.status.should be(200)

      returned_data =  Hashie::Mash.new( JSON.parse( response.body ) )

      perspectives = returned_data.perspectives
      perspectives.count.should == 2
      perspectives[1].memo.should include("COSMIC")
      perspectives[0].memo.should include("LIB SQUARE")
    end

    it "by closest distance" do
      get user_perspectives_path(@user), {:lat=>49.2642380, :long=>-123.1625990, :format => :json}
      response.status.should be(200)

      returned_data =  Hashie::Mash.new( JSON.parse( response.body ) )

      perspectives = returned_data.perspectives
      perspectives.count.should == 2
      perspectives[1].memo.should include("LIB SQUARE")
      perspectives[0].memo.should include("COSMIC")
    end


  end


  describe "perspective can be added" do

    it "to a completely new place" do
      user = Factory.create(:user, :username=>'tyler', :password=>'foofoo')

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      post_via_redirect places_path, {
        :format => 'json',
        :name => "Casa MacKinnon",
        :lat => 49.268547,
        :long => -123.15279,
        :memo => "This is where the magic happens"
      }

      response.status.should be(200)

      #make sure perspective has been added, but place count is still 1
      place = Place.all().first

      perspective = place.perspectives.where(:user_id => user.id).first
      perspective.memo.should include("magic happens")

    end

    it "to a new place that exists on Google Places and the system" do
      user = Factory.create(:user, :email=>'tyler@placeling.com', :password=>'foofoo')
      place = Factory.create(:place, :google_id =>"a648ca9b8af31e9726947caecfd062406dc89440")

      #make sure place already exists
      Place.find_by_google_id(place.google_id).should be_valid

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      post_via_redirect places_perspectives_path, {
        :format => 'json',
        :google_ref=> 'CnRqAAAAENm_o7U-bsSFgVriK3TWgSX04_dXx9_LQx52SEEe77eIWhU8hrJUI9p8UCP-uyzcUMPPEJDu9WjdRR9Sl3Y5-_FBd-Mr1c6x4DocgErDdRMr3nykG7r1_SC4gBBH9amVAcpJvP80bN8LD94leLBpkRIQmP_0UC128e_Co4mg1H9vEhoU960SUeBMRddoH6mTUgUpm6op838',
        :google_id=>"a648ca9b8af31e9726947caecfd062406dc89440",
        :memo => "This place is out of this world",
        :lat => 49.268547,
        :long => -123.15279,
        :accuracy=>'500'
      }

      response.status.should be(200)

      #make sure perspective has been added, but place count is still 1
      place_query = Place.where(:google_id => "a648ca9b8af31e9726947caecfd062406dc89440")
      place_query.count.should be(1)
      place = place_query.first

      perspective = place.perspectives.where(:user_id=> user.id).first
      perspective.memo.should include("out of this world")

    end

    it "to a new place that exists on Google Places but not the system" do
      # 49.268547,-123.15279 - Ian's House

      user = Factory.create(:user, :email=>'tyler@placeling.com', :password=>'foofoo')

      #make sure place doesn't already exist
      Place.find_by_google_id("a648ca9b8af31e9726947caecfd062406dc89440").should be_nil

      post_via_redirect user_session_path, 'user[login]' => user.email, 'user[password]' => user.password

      post_via_redirect places_path, {
        :format => 'json',
        :google_ref=> 'CnRqAAAAENm_o7U-bsSFgVriK3TWgSX04_dXx9_LQx52SEEe77eIWhU8hrJUI9p8UCP-uyzcUMPPEJDu9WjdRR9Sl3Y5-_FBd-Mr1c6x4DocgErDdRMr3nykG7r1_SC4gBBH9amVAcpJvP80bN8LD94leLBpkRIQmP_0UC128e_Co4mg1H9vEhoU960SUeBMRddoH6mTUgUpm6op838',
        :google_id=>"a648ca9b8af31e9726947caecfd062406dc89440",
        :memo => "This place is da bomb",
        :lat => 49.268547,
        :long => -123.15279,
        :accuracy=>'500'
      }

      response.status.should be(200)

      #make sure place and perspective has been added
      place =  Place.find_by_google_id("a648ca9b8af31e9726947caecfd062406dc89440")
      place.should be_valid

      perspective = place.perspectives.where(:user_id=> user.id).first
      perspective.memo.should include("da bomb")

    end
  end


  describe "GET nearby_places for JSON request" do
    it "should do show nearby places for a co-ordinate" do
      get nearby_places_path, {:format => "json",:lat => '-33.8599827', :long =>'151.2021282', :accuracy=>'500'}
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