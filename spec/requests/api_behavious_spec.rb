require "spec_helper"
require 'json/ext'
require 'carrierwave/test/matchers'

describe "API - " do

  describe "home activity feed" do
    it "shows other user's activity" do
      user = Factory.create(:user)
      user2 = Factory.create(:user)
      user3 = Factory.create(:user)

      user.follow( user2 )
      user.follow( user3 )

      user2.follow( user3 )
      perspective = Factory.create(:perspective, :user=>user2)
      perspective2 = Factory.create(:perspective, :user=>user3)

      user2.star( perspective )

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      get activity_user_path( user ), {
         :format => 'json'
      }

      response.status.should be(200)

    end
  end

  describe "images can" do
    include CarrierWave::Test::Matchers

    it "be added to an existing perspective" do
      user = Factory.create(:user)
      perspective = Factory.create(:perspective, :user =>user)

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      post_via_redirect place_photos_path(perspective.place), {
        :format => 'json',
        :title => "Ian's Tattoo'",
        :image => Rack::Test::UploadedFile.new( "#{Rails.root}/spec/fixtures/IMG_0288.JPG", 'image/jpg' )
      }

      response.status.should be(200)

      #reget from db
      perspective = Perspective.find( perspective.id)
      perspective.pictures.count.should be(1)
      pic = perspective.pictures.first
      pic.image.thumb.should be_no_larger_than(160,160)
    end


    it "be added to a new perspective" do
      user = Factory.create(:user)
      place = Factory.create(:place)

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      post_via_redirect place_photos_path(place), {
        :format => 'json',
        :image => Rack::Test::UploadedFile.new( "#{Rails.root}/spec/fixtures/IMG_0288.JPG", 'image/jpg' )
      }

      response.status.should be(200)

      #reget from db
      perspective = user.perspective_for_place( place )
      perspective.pictures.count.should be(1)
      pic = perspective.pictures.first
      pic.image.thumb.should be_no_larger_than(160,160)
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

  end

  describe "deleting perspectives" do
    it "can be done by the user who created it" do
      user = Factory.create(:user)
      perspective = Factory.create(:perspective, :user =>user)
      pid = perspective.place.id

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      delete place_perspectives_path(perspective.place), {
        :format => 'json'
      }

      response.status.should be(200)

      #reget from db
      perspective = Perspective.find(perspective.id)
      perspective.should be(nil)

      place = Place.find( pid )
      place.perspective_count.should == 0
    end

    it "cannot be done by the user who did not create it" do
      user = Factory.create(:user)
      hacker = Factory.create(:user, :username=>"badperson")
      perspective = Factory.create(:perspective, :user =>user)

      post_via_redirect user_session_path, 'user[login]' => hacker.username, 'user[password]' => hacker.password

      delete place_perspectives_path(perspective.place), {
        :format => 'json'
      }

      response.status.should be(200)

      #reget from db
      perspective = Perspective.find(perspective.id)
      perspective.should_not be(nil)
    end


    it "only deletes the one perspective on a place" do
      user = Factory.create(:user)
      user2 = Factory.create(:user, :username=>"otherperson")
      perspective = Factory.create(:perspective, :user =>user)
      place = perspective.place
      perspective2 = Factory.create(:perspective, :user => user2, :place => place)

      post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

      delete place_perspectives_path(perspective.place), {
        :format => 'json'
      }

      response.status.should be(200)

      #reget from db
      perspective = Perspective.find(perspective.id)
      perspective.should be(nil)

      perspective = Perspective.find(perspective2.id)
      perspective.should_not be(nil)
    end
  end

end