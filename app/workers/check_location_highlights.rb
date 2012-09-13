class CheckLocationHighlights
  @queue = :apns_queue

  def self.perform(user_id, lat, lng, accuracy, timestamp)

    if timestamp + 60 < Time.now.to_i || accuracy >500
      #would be out of date, probably not valid
      return
    end

    user = User.find(user_id)
    perspectives = Perspective.find_nearby_for_user(user, [lat, lng], 0.004, 0, 20)

    highlights = user.highlighted_places
    highlights.shuffle!

    perspectives.each do |perspective|
      if highlights.include? perspective.place.id
        if user.ios_notification_token
          Resque.enqueue(SendNotifications, user.id, "#{perspective.place.name} is near you!", "placeling://places/#{perspective.place.id}")
        end
        break
      end
    end
  end
end