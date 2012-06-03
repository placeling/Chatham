class UpdatePlacemarkActivity
  @queue = :activity_queue
  def self.perform(actor_id, perspective_id, fb_post = false)

    perspective = Perspective.find( perspective_id )

    actor1 = User.find( actor_id )
    activity = actor1.build_activity

    Rails.logger.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{actor1.username} updated placemark #{perspective.place.name}, OG?: #{!actor1.facebook.nil?}"

    activity.activity_type = "UPDATE_PERSPECTIVE"

    activity.subject = perspective.id
    activity.subject_title = perspective.place.name

    activity.save
    activity.push_to_followers( actor1 )

    if fb_post && actor1.facebook #&& !(Rails.env.development? || Rails.env.test?)
      image_url=nil
      for picture in perspective.pictures
        if !picture.fb_posted
          image_url = picture.main_url(nil)
          picture.fb_posted = true
          picture.save
          break
        end
      end

      if !image_url.nil?
        Rails.logger.info "Sending Placemark for #{actor1.username} on #{perspective.place.name} to facebook with image #{image_url}"
        actor1.facebook.og_action!("placeling:placemark",
                                 :location => perspective.og_path,
                                 "image[0][url]" => image_url,
                                  "image[0][user_generated]" =>true)
      else
        actor1.facebook.og_action!("placeling:placemark",:location => perspective.og_path)
      end
    end

  end
end