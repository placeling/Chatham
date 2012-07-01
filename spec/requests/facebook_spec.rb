require "spec_helper"

describe "Facebook" do


  before(:all) do
    #clear existing facebook users before we start a test
    @test_users = Koala::Facebook::TestUsers.new(:app_id => CHATHAM_CONFIG['facebook_app_id'], :secret => CHATHAM_CONFIG['facebook_app_secret'])

    @test_users.list.each do |user|
      @test_users.delete(user)
    end

  end

  it "checked already logged in and return false for new user" do

    @test_users = Koala::Facebook::TestUsers.new(:app_id => CHATHAM_CONFIG['facebook_app_id'], :secret => CHATHAM_CONFIG['facebook_app_secret'])

    user = @test_users.create(true, "publish_stream")
    graph = Koala::Facebook::API.new(user["access_token"])
    profile = graph.get_object("me")

    post_via_redirect "/auth/facebook/login", {
        :format => :json,
        :uid => user['id'],
        :token => user['access_token'],
        :expiry => 2.months.from_now
    }

    response.status.should be(200)

    response_dict = JSON.parse(response.body)
    response_dict['status'].should == "fail"

  end

  it "should allow a user to signup with facebook credentials" do
    @test_users = Koala::Facebook::TestUsers.new(:app_id => CHATHAM_CONFIG['facebook_app_id'], :secret => CHATHAM_CONFIG['facebook_app_secret'])

    user = @test_users.create(true, "publish_stream")

    post_via_redirect "/v1/users", {
        :format => :json,
        :facebook_id => user['id'],
        :facebook_access_token => user['access_token'],
        :facebook_expiry_date => 2.months.from_now,
        :username => "test_username",
        :email => user["email"]
    }

    response.status.should be(200)

    response_dict = JSON.parse(response.body)
    response_dict['status'].should == "success"
    # response_dict['token'].should_not be_nil  won't have a token because there is no current_client_application
    User.count.should == 1
    User.first.authentications.count.should ==1

  end
end