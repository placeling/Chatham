require 'spec_helper'

describe QuestionsController do
  render_views

  describe "GET index" do
    it "assigns all questions as @questions" do
      Factory.create(:question, :title => "What is the best dive bar in Vancouver?")
      Factory.create(:question, :title => "What is the best sushi in Vancouver?")

      user = Factory.create(:admin)
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user

      get :index
      response.should be_success
    end
  end

  describe "GET show" do
    it "assigns the requested question as @question" do
      question = Factory.create(:question)
      get :show, :id => question.slug
      response.should be_success
    end
  end

  describe "GET show" do
    it "assigns the requested question as @question" do
      question = Factory.create(:question)
      get :share, :id => question.slug
      response.should be_success
    end
  end


  describe "GET new" do
    it "assigns a new question as @question" do
      user = Factory.create(:user)
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user

      get :new
      response.should be_success
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Question" do
        user = Factory.create(:user)
        @request.env["devise.mapping"] = Devise.mappings[:user]
        sign_in user

        expect {
          post :create, :question => {:city_name => "Toronto, ON, Canada", :title => "Where can I get a milkshake", :country_code => "ca", :location => [49.261226, -123.1139268]}
        }.to change(Question, :count).by(1)

        Question.first.title.should == "Where can I get a milkshake in Toronto, ON, Canada?"
      end

    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved question as @question" do
        user = Factory.create(:user)
        @request.env["devise.mapping"] = Devise.mappings[:user]
        sign_in user

        post :create, :question => {}
        assigns(:question).should be_a_new(Question)
      end
    end
  end


  describe "DELETE destroy" do
    it "destroys the requested question" do

      user = Factory.create(:user)
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user

      question = Factory.create(:question, :user => user)
      expect {
        delete :destroy, :id => question.id
      }.to change(Question, :count).by(-1)
    end

    it "doesn't destroy the requested question if not same user" do

      user = Factory.create(:user)
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user

      question = Factory.create(:question)
      expect {
        delete :destroy, :id => question.id
      }.to change(Question, :count).by(0)
    end

  end

end
