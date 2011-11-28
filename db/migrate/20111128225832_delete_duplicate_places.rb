class DeleteDuplicatePlaces < Mongoid::Migration
  def self.up
    places = Place.where({})
    
    # Part 1: Find duplicate places based upon Google ID (gid)
    
    gids = {}
    dupes = []
    
    places.each do |place|
      if gids.include?(place.gid)
        gids[place.gid] += 1
      else
        gids[place.gid] = 1
      end
    end
    
    gids.keys.each do |gid|
      if gids[gid] > 1
        dupes << gid
      end
    end
    
    # Part 2: Delete duplicates
    
    dupes.each do |gid|
      # Find the places with the gid
      places = Place.where(:gid => gid)
      
      # Pick the place to keep
      winner = places[0]
      
      # Pick the IDs to delete
      to_delete = []
      places.each do |place|
        if place.id != winner.id
          to_delete << place
        end
      end
      
      # Loop over perspectives with the IDs to delete and set to correct one
      to_delete.each do |target|
        perps = Perspective.where(:plid => target.id)
        perps.each do |perp|
          perp.place = winner
          perp.save
        end

        # Delete the duplicate places
        not_for_long = Place.where(:_id => target.id)
        not_for_long[0].destroy
      end
    end
  end

  def self.down
  end
end