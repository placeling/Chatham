require 'spec_helper'

describe AnswersController do
  render_views

  it "can be submitted for question" do
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

  it "can be submitted for question if not in system" do

    question = Factory.create(:question, :location => [43.6481, -79.4042])

    post :create, {
        :question_id => question.id,
        :google_id_place => "c66f0806f7d5db9fd21232afa0457e64e3f6651f",
        :google_ref_place => "CmRdAAAAJj27uANREN19pMYBNr4HjedJKxSrzhMTmsoGsBnPwdCgT2XLaiRid-v6ZHLhgPqRd-EOZKP7kNe0iinn8YrHblyxCeOMR4-85y5Bebhakx4N70I-nb55VMImpWN0hXEAEhBcUGMMANpKC1ALIHYCoM6SGhRV79MCudi6ZMakcXZyQQcmRean8Q"

    }

    Question.first.answers.count.should == 1
    Question.first.answers.first.place.name.should == "Bellevue"
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