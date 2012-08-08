require 'spec_helper'

describe PlacemarkCommentsController do


  describe "GET 'index'" do
    it "should return list of comments for perspective" do
      perspective = Factory.create(:perspective)

      user = Factory.create(:user)
      comment = perspective.placemark_comments.build()
      comment.comment = "this is a remarkably average comment"
      comment.user = user
      comment.save

      get :index, :perspective_id => perspective.id, :format => :json

      response.should be_success

      returnedjson = JSON.parse(response.body)

      returnedjson['placemark_comments'].count.should == 1

      returnedjson['placemark_comments'][0]['comment'].should == "this is a remarkably average comment"
    end
  end

  describe "POST 'create'" do
    it "should attach a comment to placemark" do
      perspective = Factory.create(:perspective)

      user = Factory.create(:user)
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user

      post :create, {:perspective_id => perspective.id, :format => :json,
                     :placemark_comment => {
                         :comment => "This is an awesome placemark"
                     }
      }

      response.should be_success

      perspective.reload

      perspective.placemark_comments.count.should == 1
    end
  end

end
