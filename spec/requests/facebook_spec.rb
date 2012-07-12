require "spec_helper"

describe "Facebook" do


  before(:all) do
    #clear existing facebook users before we start a test
    @test_users = Koala::Facebook::TestUsers.new(:app_id => CHATHAM_CONFIG['facebook_app_id'], :secret => CHATHAM_CONFIG['facebook_app_secret'])
    @test_users.delete_all
  end

  before(:each) do
    #this is cool because each environment has its own namespace
    $redis.flushall
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


  it "can be used to log-in an existing user if already facebook authed" do
    @test_users = Koala::Facebook::TestUsers.new(:app_id => CHATHAM_CONFIG['facebook_app_id'], :secret => CHATHAM_CONFIG['facebook_app_secret'])

    fb_user = @test_users.create(true, "publish_stream")
    user = Factory.create(:user, :email => fb_user["email"])
    user.authentications.create(:expiry => 2.months.from_now, :provider => "facebook", :uid => fb_user['id'], :token => fb_user['access_token'])

    current_client_application = Factory.create(:client_application)

    post_via_redirect "/auth/facebook/login", {
        :format => :json,
        :newlogin => true,
        :uid => fb_user['id'],
        :token => fb_user['access_token'],
        :expiry => 2.months.from_now
    }

    response.status.should be(200)

    response_dict = JSON.parse(response.body)
    response_dict['status'].should == "success"

    User.count.should == 1
    User.first.authentications.count.should ==1

  end

  it "credentials can be added to an existing user" do
    @test_users = Koala::Facebook::TestUsers.new(:app_id => CHATHAM_CONFIG['facebook_app_id'], :secret => CHATHAM_CONFIG['facebook_app_secret'])
    user = Factory.create(:user)

    User.count.should == 1
    User.first.authentications.count.should ==0

    fb_user = @test_users.create(true, "publish_stream")

    post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

    post_via_redirect "/auth/facebook/add", {
        :format => :json,
        :uid => fb_user['id'],
        :token => fb_user['access_token'],
        :expiry => 2.months.from_now
    }

    response.status.should be(200)

    response_dict = JSON.parse(response.body)
    response_dict['user']['id'].should == user.id.to_s

    User.count.should == 1
    User.first.authentications.count.should ==1

  end

  it "checks for existing facebook friends, notifies them, and pre-seeds friends list" do
    @test_users = Koala::Facebook::TestUsers.new(:app_id => CHATHAM_CONFIG['facebook_app_id'], :secret => CHATHAM_CONFIG['facebook_app_secret'])

    fb_user1 = @test_users.create(true, "publish_stream")
    fb_user2 = @test_users.create(true, "publish_stream")
    fb_user3 = @test_users.create(true, "publish_stream")

    @test_users.befriend(fb_user1, fb_user2)
    @test_users.befriend(fb_user1, fb_user3)

    user2 = Factory.create(:user, :email => fb_user2["email"])
    user2.ios_notification_token = "FAKEIOSTOKENFORTESTING"
    user2.save
    user2.authentications.create(:expiry => 2.months.from_now, :provider => "facebook", :uid => fb_user2['id'], :token => fb_user2['access_token'])

    user3 = Factory.create(:user, :email => fb_user3["email"])
    user3.authentications.create(:expiry => 2.months.from_now, :provider => "facebook", :uid => fb_user3['id'], :token => fb_user3['access_token'])

    user1 = Factory.create(:user, :email => fb_user1["email"])
    user1.authentications.create(:expiry => 2.months.from_now, :provider => "facebook", :uid => fb_user1['id'], :token => fb_user1['access_token'])

    $redis.smembers("facebook_friends_#{user1.id}").count.should == 2

    User.count.should == 3
    Authentication.count.should == 3

    user2.notifications.count.should == 1 #notifications should be sent
    user2.notifications[0].type.should == "FACEBOOK_FRIEND"
    user3.notifications.count.should == 0

  end


end