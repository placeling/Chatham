class UpdatePlacemarkActivity
  @queue = :activity_queue

  def self.perform(actor_id, perspective_id, fb_post = false, twitter_post = false)

    perspective = Perspective.find(perspective_id)

    return unless !perspective.nil? #was probably deleted

    actor1 = User.find(actor_id)
    activity = actor1.build_activity

    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{actor1.username} updated placemark #{perspective.place.name}, OG?: #{!actor1.facebook.nil?}"

    activity.activity_type = "UPDATE_PERSPECTIVE"

    activity.subject = perspective.id
    activity.subject_title = perspective.place.name

    #check if a "recent" activity, most recent 20
    actor1.activity_feed.activities.each do |act|
      if (act.activity_type == "UPDATE_PERSPECTIVE" || act.activity_type == "NEW_PERSPECTIVE") && activity.subject == act.subject
        return
      end
    end

    activity.save
    activity.push_to_followers(actor1)

    if fb_post && actor1.post_facebook? && Rails.env.production?
      Resque.enqueue(FacebookPost, actor1.id, "placeling:set", {:placemark => perspective.og_path})
      #actor1.facebook.put_connections("me", "placeling:set", :placemark => perspective.og_path)
    end

    if twitter_post && actor1.twitter && Rails.env.production?
      if  perspective.memo.length > 1
        tweet_status = perspective.twitter_text
      else
        tweet_status = "Just updated my placemark for #{perspective.place.name}#{" (w/ pic)" unless perspective.pictures.count==0} #{perspective.og_path}"
      end
      Resque.enqueue(TwitterPost, actor1.id, tweet_status, perspective.place.location[0], perspective.place.location[1])
    end

  end
end