class AnswerQuestion
  @queue = :activity_queue

  def self.perform(actor1_id, question_id)

    actor1 = User.find(actor1_id)

    question = Question.find(question_id)

    activity = actor1.build_activity

    activity.activity_type = "ANSWER_QUESTION"

    activity.subject = question.id
    activity.subject_title = question.title
    #activity.save
    #activity.push_to_followers(actor1)

    if actor1.facebook && Rails.env.production?
      actor1.facebook.og_action!("placeling:answer", :question => question.og_path)
    end

  end
end