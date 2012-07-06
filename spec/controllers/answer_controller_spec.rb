require 'spec_helper'

describe AnswersController do
  render_views

  it "should can be submitted for question" do
    place = Factory.create(:place)

    question = Factory.create(:question)

    post :create, {
        :format => :json,
        :question_id => question.id,
        :google_id_place => place.google_id
    }

    response.should be_success

    Question.first.answers.count.should == 1
    Question.first.score.should == 1
  end

  it "can be upvoted" do
    place = Factory.create(:place)

    question = Factory.create(:question, :score => 1)
    answer = question.answers.create(:upvotes => 1, :place => place)

    post :upvote, {
        :format => :json,
        :question_id => question.id,
        :id => answer.id
    }

    response.should be_success

    Question.first.answers.count.should == 1
    Question.first.score.should == 2
  end


  it "should can be submitted for question while logged in" do
    place = Factory.create(:place)

    user = Factory.create(:user)
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in user

    question = Factory.create(:question)

    post :create, {
        :format => :json,
        :question_id => question.id,
        :google_id_place => place.google_id
    }

    response.should be_success

    Question.first.answers.count.should == 1
    Question.first.score.should == 1
  end

  it "can be upvoted while logged in" do
    place = Factory.create(:place)

    user = Factory.create(:user)
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in user

    question = Factory.create(:question, :score => 1)
    answer = question.answers.create(:upvotes => 1, :place => place)

    post :upvote, {
        :format => :json,
        :question_id => question.id,
        :id => answer.id
    }

    response.should be_success

    Question.first.answers.count.should == 1
    Question.first.score.should == 2
  end


end