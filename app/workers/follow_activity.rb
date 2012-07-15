class FollowActivity
  @queue = :activity_queue

  def self.perform(actor1_id, actor2_id)

    actor1 = User.find(actor1_id)
    actor2 = User.find(actor2_id)

    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{actor1.username} followed #{actor2.username}, notification?:#{actor2.follow_notification?}, OG?: #{!actor1.facebook.nil?}"

    activity = actor1.build_activity

    activity.activity_type = "FOLLOW"

    activity.actor2 = actor2.id
    activity.username2 = actor2.username

    #check if a "recent" activity, most recent 20
    actor1.activity_feed.activities.each do |act|
      if act.activity_type == activity.activity_type && activity.actor2 == act.actor2
        return
      end
    end

    activity.save
    activity.push_to_followers(actor1)

    if actor1.post_facebook? && Rails.env.production?
      actor1.facebook.put_connections("me", "placeling:follow", :user => actor2.og_path)
      #actor1.facebook.put_connection("me", "og:follows", :profile => actor2.og_path)
    end

    unless Notification.veto(activity)
      apns = false
      email = false
      if actor2.follow_notification?
        Resque.enqueue(SendNotifications, actor2.id, "#{actor1.username} started following you!", "placeling://users/#{actor1.username}")
        apns = true
      end
      if actor2.follow_email?
        Notifier.follow(actor2.id, actor1.id).deliver!
        email = true
      end

      notification = Notification.new(:actor1 => actor1.id, :actor2 => actor2.id, :type => activity.activity_type, :subject_name => actor1.username, :email => email, :apns => apns)
      notification.remember #redis backed
    end

  end
end