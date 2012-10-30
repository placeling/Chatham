class AnswerQuestion
  @queue = :activity_queue

  def self.perform(actor1_id, question_id, answer_id)

    question = Question.find(question_id)

    if actor1_id
      actor1 = User.find(actor1_id)

      activity = actor1.build_activity
      activity.activity_type = "ANSWER_QUESTION"

      activity.subject = question.id
      activity.subject_title = question.title
      #activity.save
      #activity.push_to_followers(actor1)
      if actor1.post_facebook? && Rails.env.production?
        actor1.facebook.put_connections("me", "placeling:answer", :question => question.og_path)
      end
    end

    question.subscribers.each do |subscriber_id|
      mail = Notifier.question_answered(subscriber_id, question_id, answer_id, actor1_id)
      mail.deliver
    end

  end
end