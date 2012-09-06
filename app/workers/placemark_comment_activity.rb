class PlacemarkCommentActivity
  @queue = :activity_queue

  def self.perform(actor1_id, actor2_id, perspective_id)

    actor1 = User.find(actor1_id)
    actor2 = User.find(actor2_id)
    perspective = Perspective.find(perspective_id)

    activity = actor1.build_activity

    activity.activity_type = "COMMENT_PERSPECTIVE"

    activity.actor2 = actor2.id
    activity.username2 = actor2.username

    activity.subject = perspective.id
    activity.subject_title = perspective.place.name

    #check if a "recent" activity, most recent 20

    unless Notification.veto(activity)
      apns = false
      email = false
      if actor2.comment_notification?
        Resque.enqueue(SendNotifications, actor2_id, "#{actor1.username} commented on your placemark for #{perspective.place.name}!", "placeling://perspectives/#{perspective.id}")
        apns = true
      end

      notification = Notification.new(:actor1 => actor1.id, :actor2 => actor2.id, :subject => perspective.id, :type => activity.activity_type, :subject_name => perspective.place.name, :email => email, :apns => apns)
      notification.remember #redis backed
    end
  end
end