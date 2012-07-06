class StarActivity
  @queue = :activity_queue

  def self.perform(actor1_id, actor2_id, perspective_id)

    actor1 = User.find(actor1_id)
    actor2 = User.find(actor2_id)
    perspective = Perspective.find(perspective_id)

    activity = actor1.build_activity

    activity.activity_type = "STAR_PERSPECTIVE"

    activity.actor2 = actor2.id
    activity.username2 = actor2.username

    activity.subject = perspective.id
    activity.subject_title = perspective.place.name

    #check if a "recent" activity, most recent 20
    actor1.activity_feed.activities.each do |act|
      if act.activity_type == "STAR_PERSPECTIVE" && activity.actor2 == act.actor2 && activity.subject == act.subject
        return
      end
    end

    activity.save
    activity.push_to_followers(actor1)

    if actor1.facebook && Rails.env.production?
      actor1.facebook.og_action!("og.likes", :object => perspective.og_path)
    end

    unless Notification.veto(activity)
      apns = false
      email = false
      if actor2.remark_notification?
        Resque.enqueue(SendNotifications, actor2.id, "#{actor1.username} liked your placemark on #{ perspective.place.name }!", "placeling://places/#{perspective.place.id}")
        apns = true
      end
      if actor2.remark_email?
        Notifier.remark(actor2.id, actor1.id, perspective.id).deliver!
        email = true
      end

      notification = Notification.new(:actor1 => actor1.id, :actor2 => actor2.id, :subject => perspective.id, :type => activity.activity_type, :subject_name => perspective.place.name, :email => email, :apns => apns)
      notification.remember #redis backed
    end
  end
end