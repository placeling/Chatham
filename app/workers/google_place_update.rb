class GooglePlaceUpdate
  @queue = :google_place_queue

  def self.perform()

    if Rails.env.production?
      places = Place.where(:updated_at.lt => 1.month.ago).limit(1000)
    else
      places = Place.where(:updated_at.lt => 1.month.ago).limit(10)
    end

    gp = GooglePlaces.new

    places.each do |place|
      RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - updating #{place.name} - #{place.id}"
      if place.perspective_count == 0 && Question.any_of({'answers.place_id' => place.id}).count == 0
        place.destroy #not placemarked or answered, so delete
      elsif place.google_ref
        updatedPlace = gp.get_place(place.google_ref, false)

        oldPlace = place.clone
        if updatedPlace
          if updatedPlace.id == place.google_id
            #RESQUE_LOGGER.info "updating #{place.name}, same google ID"
            place = place.update_from_google_place(updatedPlace)
            place.save!
          elsif oldPlace.name == updatedPlace.name
            if merge_place = Place.find_by_google_id(updatedPlace.id)
              #weird case where changing to already existing id
              RESQUE_LOGGER.info "need to merge #{oldPlace.name} and #{merge_place.name} to #{updatedPlace.name}"
              place.update_flag = true
              place.save!
            else
              place = place.update_from_google_place(updatedPlace)
              place.save!
            end
          else
            if merge_place = Place.find_by_google_id(updatedPlace.id)
              #weird case where changing to already existing id
              RESQUE_LOGGER.info "need to merge #{oldPlace.name} and #{merge_place.name} to #{updatedPlace.name}"
              place.update_flag = true
              place.save
            else
              RESQUE_LOGGER.info "updating with different name #{oldPlace.name} != #{updatedPlace.name}"
              place.update_flag = true
              place.save
            end
          end
        else
          place.save #not sure what to do with these yet, so just renew their lease on life
        end
        sleep(2)
      end
    end
  end

end
