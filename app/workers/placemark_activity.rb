class PlacemarkActivity
  @queue = :activity_queue

  def self.perform(actor_id, perspective_id, fb_post = false, twitter_post = false)

    actor1 = User.find(actor_id)

    perspective = Perspective.find(perspective_id)

    if perspective.nil?
      if Perspective.deleted.find(perspective_id)
        #was deleted before this went, so all good
        return
      end
    end

    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{actor1.username} placemarked #{perspective.place.name}, OG?: #{!actor1.facebook.nil?}"

    activity = actor1.build_activity

    activity.activity_type = "NEW_PERSPECTIVE"

    activity.subject = perspective.id
    activity.subject_title = perspective.place.name

    activity.save
    activity.push_to_followers(actor1)

    if fb_post && actor1.post_facebook? && Rails.env.production?
      Resque.enqueue(FacebookPost, actor1.id, "placeling:set", {:placemark => perspective.og_path})
    end

    if twitter_post && actor1.twitter && Rails.env.production?
      if perspective.memo.length > 1
        actor1.tweet("#{perspective.place.name}: #{perspective.twitter_text}#{" (w/ pic)" unless perspective.pictures.count==0} #{perspective.og_path}", perspective.place.location[0], perspective.place.location[1])
      else
        actor1.tweet("Placemarked #{perspective.place.name}#{" (w/ pic)" unless perspective.pictures.count==0} #{perspective.og_path}", perspective.place.location[0], perspective.place.location[1])
      end
    end

  end
end