class UpdatePlacemarkActivity
  @queue = :activity_queue

  def self.perform(actor_id, perspective_id, fb_post = false)

    perspective = Perspective.find(perspective_id)

    actor1 = User.find(actor_id)
    activity = actor1.build_activity

    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{actor1.username} updated placemark #{perspective.place.name}, OG?: #{!actor1.new_facebook.nil?}"

    activity.activity_type = "UPDATE_PERSPECTIVE"

    activity.subject = perspective.id
    activity.subject_title = perspective.place.name

    #check if a "recent" activity, most recent 20
    actor1.activity_feed.activities.each do |act|
      if act.activity_type == "UPDATE_PERSPECTIVE" || act.activity_type == "NEW_PERSPECTIVE" && activity.subject == act.subject
        return
      end
    end

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

      actor1.new_facebook.put_connection("me", "placeling:set", :placemark => perspective.og_path)
    end

  end
end