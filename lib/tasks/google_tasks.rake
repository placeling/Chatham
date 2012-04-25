require 'google_places'

def update_place( place_id )
  place = Place.find( place_id )

  if place.google_ref
    gp = GooglePlaces.new

    updatedPlace = gp.get_place( place.google_ref, false )


    oldPlace = place.clone
    if updatedPlace
      if updatedPlace.id == place.google_id
        puts "same google ID"
        place = place.update_from_google_place( updatedPlace )
        place.save
      else
        puts "updated google ID, #{oldPlace.name} != #{updatedPlace.name}"
        place = place.update_from_google_place( updatedPlace )
      end
    else
      puts "didn't get place back'"
    end
  end



end


namespace "google" do


  desc "Finds places that are more than a month old and updates them"
  task :update_places => :environment do

    places = Place.where( :updated_at.lt => 1.month.ago )

    places.each do |place|
      puts "updating #{place.name} - #{place.id}"
      update_place( place.id )
      sleep( 2 )
    end

  end
end
