require "spec_helper"

describe "API - Perspective" do

  it "can be flagged" do
     user = Factory.create(:user)
     user2 = Factory.create(:user)
     perspective = Factory.create(:perspective, :user => user2)

     post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

     post flag_perspective_path(perspective), {
       :format => 'json'
     }

     response.status.should be(200)

     perspective = Perspective.find( perspective.id )
     perspective.flag_count.should == 1
  end

  it "can be updated" do
     user = Factory.create(:user)
     perspective = Factory.create(:perspective, :user => user)

     post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

     post place_perspectives_path(perspective.place), {
       :format => 'json',
       :memo => "This place is great for #breakfast"
     }

     response.status.should be(200)


     perspective = Perspective.find( perspective.id )
     perspective.memo.should include("#breakfast")
     perspective.place_stub.should_not be_nil

  end


  it "JSON call should state whether it has been starred" do
      user = Factory.create(:user)
      place = Factory.create(:place)
      perspective = Factory.create(:perspective, :place =>place)
      user.star( perspective )
      perspective.save
      user.save

      perspective2 = Factory.create(:perspective, :place =>place)
      
      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password


      get all_place_perspectives_path(place), {
        :format => 'json'
      }

      response.status.should be(200)

      showPlace = JSON.parse( response.body )
      showPlace['perspectives'].count.should == 2

      if showPlace['perspectives'][0]['starred']
        showPlace['perspectives'][1]['starred'].should == false
      else
        showPlace['perspectives'][1]['starred'].should == true
      end

  end

   it "can be starred" do
     user = Factory.create(:user)
     perspective = Factory.create(:perspective)

     post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

     post star_perspective_path(perspective), {
       :format => 'json'
     }

     response.status.should be(200)

     perspective = Perspective.find(perspective.id)
     perspective.starring_users.should include(user.id)
     perspective.fav_count.should == 1

     user_perspective = user.perspective_for_place(perspective.place)
     user_perspective.favourite_perspective_ids.should include(perspective.id)

   end


   it "can be unstarred" do
     user = Factory.create(:user)
     perspective = Factory.create(:perspective)
     place = perspective.place
     user.star( perspective )
     perspective.save
     user.save

     post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

     user_perspective = user.perspective_for_place( place )
     user_perspective.favourite_perspective_ids.should include(perspective.id)

     post_via_redirect unstar_perspective_path(perspective), {
       :format => 'json'
     }

     response.status.should be(200)
     user_perspective = Perspective.find(user_perspective.id) #regrab because should have changeds
     user_perspective.favourite_perspectives.should_not include(perspective.id)

     perspective = Perspective.find( perspective.id ) #make sure didn't delete actual perspective
     perspective.should_not be_nil
     perspective.fav_count.should == 0
   end


  describe "can be added" do
    # Marked broken as will otherwise attempt to write to Google Places API. Use lib/google_places_spec.rb instead
    it "to a completely new place", :broken => true do
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

      perspective = user.perspective_for_place( place )
      perspective.memo.should include("magic happens")

    end

    it "to a place that exists on Google Places and the system" do
      user = Factory.create(:user)
      place = Factory.create(:place, :google_id =>"a648ca9b8af31e9726947caecfd062406dc89440")

      #make sure place already exists
      Place.find_by_google_id(place.google_id).should be_valid

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      post_via_redirect place_perspectives_path( place ), {
        :format => 'json',
        :memo => "This place is out of this world #breakfast",
        :lat => 49.268547,
        :long => -123.15279,
        :accuracy=>'500'
      }

      response.status.should be(200)

      #make sure perspective has been added, but place count is still 1
      place = Place.find_by_google_id("a648ca9b8af31e9726947caecfd062406dc89440")
      Place.count.should be(1)

      perspective = user.perspective_for_place( place )
      perspective.memo.should include("out of this world")
      perspective.tags[0].should == "breakfast"

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

      perspective = user.perspective_for_place( place )
      perspective.memo.should include("da bomb")

    end

    it "with a url that gets returned" do
      user = Factory.create(:user)
      place = Factory.create(:place, :google_id =>"a648ca9b8af31e9726947caecfd062406dc89440")

      #make sure place already exists
      Place.find_by_google_id(place.google_id).should be_valid

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      post_via_redirect place_perspectives_path( place ), {
        :format => 'json',
        :memo => "This place is out of this world #breakfast",
        :lat => 49.268547,
        :url => "http://www.lunarluau.ca",
        :long => -123.15279,
        :accuracy=>'500'
      }

      response.status.should be(200)

      #make sure perspective has been added, but place count is still 1
      place = Place.find_by_google_id("a648ca9b8af31e9726947caecfd062406dc89440")
      Place.count.should be(1)

      perspective = user.perspective_for_place( place )
      perspective.url.should include("lunarluau")

    end


  end

  describe "can be shown nearby from" do

    it "all users" do
      user = Factory.create(:user)
      place = Factory.create(:place, :name => "testA", :location => [49.2682380,-123.1525990] )
      perspective_one = Factory.create(:perspective, :place =>place)

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      get nearby_perspectives_path, {
          :format => "json",
          :lat => '49.268547',
          :long =>'-123.15279',
          :span=>'1'
      }

      response.status.should be(200)
      returned_data =  Hashie::Mash.new( JSON.parse( response.body ) )
      returned_data.places.count.should == 1
      returned_data.places[0].name.should == "testA"

    end
  end
end
