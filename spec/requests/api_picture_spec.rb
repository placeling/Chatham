require "spec_helper"

describe "Picture" do

  it "can be deleted by user" do
    user = Factory.create(:user)
    picture = Factory.build(:picture)
    perspective = Factory.create(:perspective, :user =>user)
    picture = perspective.pictures.build
    picture.save

    post_via_redirect user_session_path, 'user[login]' => user.username, 'user[password]' => user.password

    delete place_photo_path(perspective.place, picture), {
       :format => 'json'
    }

    response.status.should be(200)

    perspective = Perspective.find( perspective.id )
    perspective = JSON.parse( response.body )

    perspective['pictures'].should be(nil)
  end
end

