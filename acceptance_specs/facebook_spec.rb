require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require "rspec"

describe "Facebook", :type => :request do

  before(:all) do

    ACCEPTANCE_CONFIG = YAML.load_file("#{::Rails.root.to_s}/acceptance_specs/harness.yml")[::Rails.env]
    @key = ACCEPTANCE_CONFIG['consumer_key']
    @secret = ACCEPTANCE_CONFIG['consumer_secret']
    @username = ACCEPTANCE_CONFIG['username']
    @password = ACCEPTANCE_CONFIG['password']
    @site = ACCEPTANCE_CONFIG['host']
  end

  it "should display status page" do
      puts @site + "/admin/status"

      http= Net::HTTP.new(@site, 443)
      http.use_ssl = true
      req = Net::HTTP::Get.new('/admin/status')
      res = http.request(req)

      res.code.should == "200"
      res.body.should include("E8455D251B002C7A0E0ADE385C8940E29CE7C139233B31A9889009B37814CA49")
  end

  it "can be and posted to facebook", :broken => true do
     user = Factory.create(:user)
     app = FbGraph::Application.new(CHATHAM_CONFIG['facebook_app_id'], :secret => CHATHAM_CONFIG['facebook_app_secret'])
     raw_auth = app.test_user!(:installed => true, :permissions => :publish_actions)
     user.authentications.create!(:provider => "facebook", :uid => raw_auth.identifier, :token =>raw_auth.access_token)

     perspective = Factory.create(:perspective, :user => user)

     post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

     post place_perspectives_path(perspective.place), {
       :format => 'json',
       :memo => "This place is great for #breakfast",
       :fb_post => true
     }

     response.status.should be(200)

     perspective = Perspective.find( perspective.id )
     perspective.memo.should include("#breakfast")
     perspective.place_stub.should_not be_nil

    #check facebook post
    sleep( 2 )

    actions = user.facebook.og_actions "placeling:placemark"
    action = actions.first
    action.start_time.should > 1.minute.ago
  end

end



