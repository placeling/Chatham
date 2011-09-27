require "spec_helper"

describe "Timeline" do
  it "for user shows a recent perspective being starred" do
    user = Factory.create(:user)
    user2 = Factory.create(:user)
    place = Factory.create(:place)
    perspective = Factory.create(:perspective, :place =>place, :user=>user2)

    post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

    post star_perspective_path(perspective), {
       :format => 'json'
    }

    get activity_user_path( user ), {
       :format => 'json'
    }

    response.status.should be(200)
    response_dict = JSON.parse( response.body )
    feed = response_dict['user_feed']
    feed.count.should == 1
    feed[0]['username1'].should == user.username

  end
end


describe "Users signup" , :broken => true do
    it "with an email" do

      post_via_redirect "/users", {
        :lat => "49",
        :long =>"-120",
        :username => "tyler",
        :email =>"test@gmail.com",
        :password => "skippy"
      }

      response.status.should be(200)
      response.body.should include("success")

    end

    it "get an error without an email" do

      post_via_redirect  "/users", {
        :format => :json,
        :lat => "49",
        :long =>"-120",
        :username => "tyler",
        :password => "skippy"
      }

      response.status.should be(200)

      response_dict = JSON.parse( response.body )
      response_dict['status'].should == "fail"
      response_dict['message']['email'].should include("can't be blank")

    end

    it "get an error without a username" do

      post_via_redirect  "/users", {
        :lat => "49",
        :long =>"-120",
        :password => "skippy"
      }

      response.status.should be(200)

      response_dict = JSON.parse( response.body )
      response_dict['status'].should == "fail"
      response_dict['message']['username'].should include("can't be blank")

    end
  end