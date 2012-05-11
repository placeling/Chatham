class UpdatePlacemarkActivity
  @queue = :activity_queue
  def self.perform(actor_id, perspective_id, fb_post = false)

    perspective = Perspective.find( perspective_id )

    actor1 = User.find( actor_id )
    activity = actor1.build_activity

    activity.activity_type = "UPDATE_PERSPECTIVE"

    activity.subject = perspective.id
    activity.subject_title = perspective.place.name

    activity.save
    activity.push_to_followers( actor1 )

    if fb_post && actor1.facebook #&& Rails.env.production?
      actor1.facebook.og_action!("placeling:placemark", :location => perspective.og_path )
    end
  end
end