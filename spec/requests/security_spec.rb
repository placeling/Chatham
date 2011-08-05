require "spec_helper"

describe "Security" do

  it "should not allow non-admin to auto-create access token" do

    user = Factory.create(:user)
    user2 = Factory.create(:user, :username=>"patsy")
    client_application = Factory.create(:client_application)

    post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

    post_via_redirect access_token_oauth_client_path(client_application), {
        :username => user2.username
    }

    response.status.should be(401) #basically a "fuck off, you aren't an admin'"

  end

  it "should allow admin to auto-create access token" do

    user = Factory.create(:admin)
    user2 = Factory.create(:user, :username=>"patsy")
    client_application = Factory.create(:client_application)

    post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

    post_via_redirect access_token_oauth_client_path(client_application), {
        :username => user2.username
    }

    response.status.should be(200)

  end
end