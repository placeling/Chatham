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
    activity.save
    activity.push_to_followers(actor1)

    if actor1.facebook && Rails.env.production?
      actor1.facebook.og_action!("placeling:follow", :user => actor2.og_path)
    end

    unless Notification.veto(actor2, actor1, "FOLLOW")
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

      notification = Notification.new(:user => actor2.id, :subject => actor1.id, :type => "FOLLOW", :subject_name => actor1.username, :email => email, :apns => apns)
      notification.remember #redis backed
    end

  end
end