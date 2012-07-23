class AnswerCommentNotifications
  @queue = :email_queue

  def self.perform(question_id, answer_id, answer_comment_id)

    @user = User.find(user1_id)

    @question = Question.find(question_id)
    @answer = @question.answers.where(:_id => answer_id).first
    @answer_comment = @answer.answer_comments.where(:_id => answer_comment_id).first

    return if @answer_comment.nil? #we just assume it was immediately deleted

    #first, we should send the author of the question the update provided they aren't "notified out"
    if @question.user.question_email? && @answer_comment.user.id != @question.user.id
      unless @question.user.notifications.count >= 5 && @question.user.notifications[4].created_at < 1.hour.ago
        Notifier.answer_commented(@question.user.id, @answer_comment.id).deliver

        notification = Notification.new(:actor1 => @answer_comment.user.id, :actor2 => @question.user.id, :type => "ANSWER_COMMENT", :subject_name => @answer_comment.comment, :email => true, :apns => false)
        notification.remember #redis backed
      end
    end

    commenting_users = []

    @answer.answer_comments.each do |answer_comment|
      if commenting_users.index { |x| x.id==answer_comment.user.id }
        commenting_users << answer_comment.user unless answer_comment.user.id == @question.user.id
      end
    end

    commenting_users.each do |user|
      if user.question_email? && @answer_comment.user.id != @question.user.id && @answer_comment.user.id != user.id
        unless @question.user.notifications.count >= 5 && @question.user.notifications[4].created_at < 1.hour.ago
          Notifier.answer_commented(@question.user.id, @answer_comment.id).deliver

          notification = Notification.new(:actor1 => @answer_comment.user.id, :actor2 => user.id, :type => "ANSWER_COMMENT", :subject_name => @answer_comment.comment, :email => true, :apns => false)
          notification.remember #redis backed
        end
      end
    end

  end
end