require 'spec_helper'

describe IosController do

  it "should accept a notification token for a user" do
    user = Factory.create(:user)
    token = "97be5f99 8e1010b0 c768e357 d510662e 0ce8bdce 63b55e84 5c9f5822 f05d7981"

    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in user

    post :update_token, :ios_notification_token => token, :format => :json

    response.status.should == 200

    json_response = JSON.parse( response.body )

    json_response['status'].should == "OK"
    user.reload
    user.ios_notification_token.should == token
  end
end
