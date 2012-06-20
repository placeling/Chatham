require 'spec_helper'

describe PerspectivesController do
  render_views

  it "should return a place with an embedded perspective for its 'show'" do
    #a perspective on its own is kind of useless, and perspective with a place isn't good for showing in controller
    user = Factory.create(:user)
    place = Factory.create(:place)
    perspective = Factory.create(:perspective, :user =>user, :place =>place)

    get :show, :user_id => user.id.to_s, :id => perspective.id, :format => :json

    response.status.should == 200

    json_place = JSON.parse( response.body )

    json_place['referring_perspectives'].should_not be(nil)
    json_place['id'].should ==  place.id.to_s
  end
  
  it "returns parent perspective after a starring" do
    user = Factory.create(:user)
    perspective = Factory.create(:perspective)

    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in user

    post :star, :id => perspective.id, :format => :json

    response.status.should == 200

    json_perspective = JSON.parse( response.body )

    json_perspective['perspective'].should_not be(nil)
    json_perspective['perspective']['place']['id'].should == perspective.place.id.to_s

   end

end
