class StarActivity
  @queue = :activity_queue
  def self.perform(actor1_id, actor2_id, perspective_id)

    actor1 = User.find( actor1_id )
    actor2 = User.find( actor2_id )
    perspective = Perspective.find( perspective_id )

    activity = actor1.build_activity

    activity.activity_type = "STAR_PERSPECTIVE"

    activity.actor2 = actor2.id
    activity.username2 = actor2.username

    activity.subject = perspective.id
    activity.subject_title = perspective.place.name
    activity.save
    activity.push_to_followers( actor1 )

    if actor2.remark_notification?
      Resque.enqueue(SendNotifications, actor2.id, "#{actor1.username} liked your placemark on #{ perspective.place.name }!", "placeling://places/#{perspective.place.id}")
    end
    if actor2.remark_email?
      Notifier.remark(actor2.id, actor1.id, perspective.id).deliver!
    end

    if actor1.facebook && Rails.env.production?
      actor1.facebook.og_action!("placeling:like", :location => perspective.og_path )
    end

  end
end