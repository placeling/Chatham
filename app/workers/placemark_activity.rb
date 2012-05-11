class PlacemarkActivity
  @queue = :activity_queue
  def self.perform(actor_id, perspective_id, fb_post = false)

    actor1 = User.find( actor_id )

    perspective = Perspective.find( perspective_id )

    activity = actor1.build_activity

    activity.activity_type = "NEW_PERSPECTIVE"

    activity.subject = perspective.id
    activity.subject_title = perspective.place.name

    activity.save
    activity.push_to_followers( actor1 )

    if fb_post && actor1.facebook #use in all environments
      actor1.facebook.og_action!("placeling:placemark", :location => perspective.og_path )
    end
  end
end