require 'spec_helper'

describe PublishersController do
  render_views

  describe "GET index" do
    it "assigns all publishers as @publishers" do
      publisher = Factory.create(:publisher)
      sign_in publisher.user

      get :index

      response.should be_success
      assigns(:publishers).should eq([publisher])
    end
  end

  describe "GET edit" do
    it "assigns the requested publisher as @publisher" do
      publisher = Factory.create(:publisher)
      sign_in publisher.user

      get :edit, {:id => publisher.id}
      response.should be_success
      assigns(:publisher).should eq(publisher)
    end
  end

end
