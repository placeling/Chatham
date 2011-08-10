require "spec_helper"
require 'json/ext'
require 'carrierwave/test/matchers'

describe "API - " do

  describe "images can" do
    include CarrierWave::Test::Matchers

    it "be added to an existing perspective" do
      user = Factory.create(:user)
      perspective = Factory.create(:perspective, :user =>user)

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      post_via_redirect place_perspectives_path(perspective.place), {
        :format => 'json',
        :title => "Ian's Tattoo'",
        :image => Rack::Test::UploadedFile.new( "#{Rails.root}/spec/fixtures/IMG_0288.JPG", 'image/jpg' )
      }

      response.status.should be(200)

      #reget from db
      perspective = Perspective.find( perspective.id)
      perspective.pictures.count.should be(1)
      pic = perspective.pictures.first
      pic.image.thumb.should be_no_larger_than(64, 64)
    end
  end

  describe "users can" do
    before(:each) do
      @ian = Factory.create(:user, :username=>"imack")
      @lindsay = Factory.create(:user, :username=>"lindsay")
    end

    it "be followed" do
      post_via_redirect user_session_path, 'user[login]' => @ian.username, 'user[password]' => @ian.password

      post follow_user_path(@lindsay), {:format => :json}
      response.status.should be(200)

      #need to refresh from db
      @lindsay = User.find(@lindsay.id)
      @ian = User.find(@ian.id)

      @lindsay.followers.should include(@ian)
      @ian.following.should include(@lindsay)

      @ian.followers.should_not include(@lindsay)
      @lindsay.following.should_not include(@ian)
    end

    it "be unfollowed" do
      post_via_redirect user_session_path, 'user[login]' => @ian.username, 'user[password]' => @ian.password

      post follow_user_path(@lindsay), {:format => :json}
      response.status.should be(200)

      #need to refresh from db
      @lindsay = User.find(@lindsay.id)
      @ian = User.find(@ian.id)

      @lindsay.followers.should include(@ian)
      @ian.following.should include(@lindsay)

      post unfollow_user_path(@lindsay), {:format => :json}
      response.status.should be(200)

      #need to refresh from db
      @lindsay = User.find(@lindsay.id)
      @ian = User.find(@ian.id)

      @lindsay.followers.should_not include(@ian)
      @ian.following.should_not include(@lindsay)
    end

    it "have a list of their followers returned" do
      post_via_redirect user_session_path, 'user[login]' => @ian.username, 'user[password]' => @ian.password

      post follow_user_path(@lindsay), {:format => :json}
      response.status.should be(200)

      get followers_user_path(@lindsay), {:format => :json}
      response.status.should be(200)

      returned_data =  Hashie::Mash.new( JSON.parse( response.body ) )
      returned_data.followers.count.should == 1
      returned_data.followers[0].username.should == @ian.username
    end

    it "have a list of their following returned" do
      post_via_redirect user_session_path, 'user[login]' => @ian.username, 'user[password]' => @ian.password

      post follow_user_path(@lindsay), {:format => :json}
      response.status.should be(200)

      get following_user_path(@ian), {:format => :json}
      response.status.should be(200)

      returned_data =  Hashie::Mash.new( JSON.parse( response.body ) )
      returned_data.following.count.should == 1
      returned_data.following[0].username.should == @lindsay.username
    end
  end



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
      user = Factory.create(:user)

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

    it "to a place that exists on Google Places and the system" do
      user = Factory.create(:user)
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

      user = Factory.create(:user)

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
      response.body.should include("Pylon")

      nearby = JSON.parse( response.body )
      place_found = false
      for place in nearby
        if place['id'] == "e22913360d0b946d099c7a32a77a95e49f9ead66"#Pylon Lookout
          place_found = true
          break
        end
      end

      place_found.should == true
    end

    it "should return distances to places" do
      get nearby_places_path, {:format => "json",:lat => '49.268547', :long =>'-123.15279', :accuracy=>'500'}
      response.status.should be(200)

      nearby = JSON.parse( response.body )

      for place in nearby
        place['distance'].should <= 500
      end

    end
  end

end