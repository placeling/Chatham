class GooglePlaceUpdate
  @queue = :google_place_queue

  def self.perform()

    if Rails.env.production?
      places = Place.where(:updated_at.lt => 1.month.ago).limit(100)
    else
      places = Place.where(:updated_at.lt => 1.month.ago).limit(10)
    end

    gp = GooglePlaces.new

    places.each do |place|

      if place.perspective_count == 0 && Question.any_of({'answers.place_id' => place.id}).count == 0
        RESQUE_LOGGER.info "#{place.name} - #{place.id}, no perspectives or answers, so delete"
        place.destroy

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
              RESQUE_LOGGER.info "updating #{place.name}, existing google ID, need to merge #{oldPlace.name} and #{merge_place.name} to #{updatedPlace.name}"
            else
              RESQUE_LOGGER.info "updating #{place.name}, updated google ID, same name"
              place = place.update_from_google_place(updatedPlace)
              place.save!
            end
          else
            if merge_place = Place.find_by_google_id(updatedPlace.id)
              #weird case where changing to already existing id
              RESQUE_LOGGER.info "updating #{place.name}, existing google ID, need to merge #{oldPlace.name} and #{merge_place.name} to #{updatedPlace.name}"
              #place.save
            else
              RESQUE_LOGGER.info "updating #{place.name}, updated google ID, #{oldPlace.name} != #{updatedPlace.name}"
            end
          end
        else
          RESQUE_LOGGER.info "didn't get place back for #{place.name} - #{place.id}"
        end
        sleep(2)
      end
    end
  end

end
