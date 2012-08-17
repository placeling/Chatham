class PlacemarkActivity
  @queue = :activity_queue

  def self.perform(actor_id, perspective_id, fb_post = false, twitter_post = false)

    actor1 = User.find(actor_id)

    perspective = Perspective.find(perspective_id)

    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{actor1.username} placemarked #{perspective.place.name}, OG?: #{!actor1.facebook.nil?}"

    activity = actor1.build_activity

    activity.activity_type = "NEW_PERSPECTIVE"

    activity.subject = perspective.id
    activity.subject_title = perspective.place.name

    activity.save
    activity.push_to_followers(actor1)

    if fb_post && actor1.post_facebook? && Rails.env.production?
      image_url=nil
      for picture in perspective.pictures
        if !picture.fb_posted
          image_url = picture.main_url(nil)
          picture.fb_posted = true
          picture.save
          break
        end
      end

      actor1.facebook.put_connections("me", "placeling:set", :placemark => perspective.og_path)
    end
  end
end