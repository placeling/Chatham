require 'spec_helper'

describe PerspectivesController, :broken=> true do

  it "should return associated photos in its json" do

    user = Factory.create(:user)
    picture = Factory.build(:picture)
    perspective = Factory.create(:perspective, :user =>user)
    picture = perspective.pictures.build
    picture.save

    get :show, :user_id => user.id.to_s, :id => perspective.id, :format => :json

    response.status.should be(200)

    perspective = JSON.parse( response.body )

    perspective['pictures'].should_not be(nil)

  end

  it "should return user and place in its json" do

    user = Factory.create(:user)
    place = Factory.create(:place)
    perspective = Factory.create(:perspective, :user =>user, :place =>place)

    get :show, :user_id => user.id.to_s, :id => perspective.id, :format => :json

    response.status.should be(200)

    perspective = JSON.parse( response.body )

    perspective['place'].should_not be(nil)
    perspective['user'].should_not be(nil)

  end

end
