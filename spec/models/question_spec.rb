require 'spec_helper'

describe Question do

  describe "nearby questions" do
    it "should return nothing if there are no available answers" do

      q1 = Factory.create(:question, :title => "What is the best dive bar in Vancouver?")
      q2 = Factory.create(:question, :title => "What is the best sushi in Vancouver?")

      Question.nearby_questions(q1.location[0], q1.location[1]).count.should == 0

    end

    it "should return not return far away questions" do

      q1 = Factory.create(:question, :title => "What is the best dive bar in Vancouver?", :score => 1)

      q2 = Factory.create(:question, :title => "What is the best sushi in Vancouver?")

      Question.nearby_questions(0.0, 0.0).count.should == 0

    end


    it "should return questions that have  of the places" do

      q1 = Factory.create(:question, :title => "What is the best dive bar in Vancouver?", :score => 1)
      q2 = Factory.create(:question, :title => "What is the best sushi in Vancouver?")

      Question.nearby_questions(q1.location[0], q1.location[1]).count.should == 1

    end

  end
end