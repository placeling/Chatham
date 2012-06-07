class AnswersController < ApplicationController
  def create
    @question =Question.find( params['question_id'])



  end

  def upvote
  end
end
