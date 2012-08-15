require 'spec_helper'

describe SuggestionsController do

  describe "GET index" do
    it "assigns all suggestions as @suggestions" do
      suggestion = Factory.create(:suggestion)

      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in suggestion.receiver

      get :index, :user_id => suggestion.receiver.id
      assigns(:suggestions).should eq([suggestion])
    end
  end

  describe "GET show" do
    it "assigns the requested suggestion as @suggestion" do
      suggestion = Factory.create(:suggestion)
      get :show, {:id => suggestion.to_param}
      assigns(:suggestion).should eq(suggestion)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Suggestion" do
        user = Factory.create(:user)

        @request.env["devise.mapping"] = Devise.mappings[:user]
        sign_in user

        suggestion = Factory.build(:suggestion)
        expect {
          post :create, :user_id => suggestion.receiver.id, :suggestion => {:message => suggestion.message, :place_id => suggestion.place.id}
        }.to change(Suggestion, :count).by(1)
      end

      it "assigns a newly created suggestion as @suggestion" do
        user = Factory.create(:user)
        suggestion = Factory.build(:suggestion)

        @request.env["devise.mapping"] = Devise.mappings[:user]
        sign_in user

        post :create, :user_id => suggestion.receiver.id, :suggestion => {:message => suggestion.message, :place_id => suggestion.place.id}
        assigns(:suggestion).should be_a(Suggestion)
        assigns(:suggestion).should be_persisted
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested suggestion" do
      user = Factory.create(:admin)
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user

      suggestion = Factory.create(:suggestion)
      expect {
        delete :destroy, {:id => suggestion.to_param}
      }.to change(Suggestion, :count).by(-1)
    end
  end

end
