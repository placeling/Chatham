class FollowActivity
  @queue = :activity_queue
  def self.perform(actor1_id, actor2_id)

    actor1 = User.find( actor1_id )
    actor2 = User.find( actor2_id )

    activity = actor1.build_activity

    activity.activity_type = "FOLLOW"

    activity.actor2 = actor2.id
    activity.username2 = actor2.username
    activity.save
    activity.push_to_followers( actor1 )

    if actor2.follow_notification?
      Resque.enqueue(SendNotifications, actor2.id, "#{actor1.username} started following you!", "placeling://users/#{actor1.username}")
    end

    if actor1.facebook && Rails.env.production?
      actor1.facebook.og_action!("placeling:follow", :user => "https://www.placeling.com#{ Rails.application.routes.url_helpers.user_path(@user) }")
    end

  end
end