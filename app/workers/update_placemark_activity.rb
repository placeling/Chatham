class UpdatePlacemarkActivity
  @queue = :activity_queue
  def self.perform(actor_id, perspective_id)

    perspective = Perspective.find( perspective_id )

    if perspective.updated_at < 1.day.ago
      actor1 = User.find( actor_id )
      activity = actor1.build_activity

      activity.activity_type = "UPDATE_PERSPECTIVE"

      activity.subject = perspective.id
      activity.subject_title = perspective.place.name

      activity.save
    end
  end
end