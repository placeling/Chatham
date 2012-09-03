class SendSuggestion
  @queue = :activity_queue

  def self.perform(suggestion_id)

    suggestion = Suggestion.find(suggestion_id)

    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{suggestion.sender.username} suggested #{suggestion.place.name} to #{suggestion.receiver.username}"

    notifications = suggestion.receiver.notifications

    if (notifications.count < 5 || notifications[4].created_at < 1.day.ago)
      apns = false
      email = false
      if suggestion.receiver.suggestion_notification?
        Resque.enqueue(SendNotifications, suggestion.receiver.id, "#{suggestion.sender.username} suggested you try #{ suggestion.place.name }!", "placeling://suggestions/#{suggestion.id}")
        apns = true
      end

      notification = Notification.new(:actor1 => suggestion.sender.id, :actor2 => suggestion.receiver.id, :subject => suggestion.id, :type => "SUGGESTED_PLACE", :subject_name => suggestion.place.name, :email => email, :apns => apns)
      notification.remember #redis backed
    end

  end
end