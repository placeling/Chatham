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
  end
end