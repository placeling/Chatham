require "spec_helper"

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