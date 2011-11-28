require 'spec_helper'

describe PerspectivesController do

  it "should return associated photos in its json" do

    user = Factory.create(:user)
    picture = Factory.build(:picture)
    perspective = Factory.create(:perspective, :user =>user)
    picture = perspective.pictures.build
    picture.save

    get :show, :user_id => user.id.to_s, :id => perspective.id, :format => :json

    response.status.should == 200

    perspective = JSON.parse( response.body )

    perspective['pictures'].should_not be(nil)

  end

  it "should return user and place in its json" do

    user = Factory.create(:user)
    place = Factory.create(:place)
    perspective = Factory.create(:perspective, :user =>user, :place =>place)

    get :show, :user_id => user.id.to_s, :id => perspective.id, :format => :json

    response.status.should == 200

    perspective = JSON.parse( response.body )

    perspective['place'].should_not be(nil)
    perspective['user'].should_not be(nil)

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
    json_perspective['perspective']['plid'].should == perspective.place.id.to_s

   end

end
