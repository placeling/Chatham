class RemoveDupes < Mongoid::Migration
  def self.up
    places = Place.where({})
    
    places_to_destroy = []
    
    places.each do |place|
      if place.perspectives.nil? or place.perspectives.length == 0
        gids = Place.where({:gid => place.gid})
        if gids.length > 1
          puts place.name
          places_to_destroy << place.id
        end
      end
    end
    
    places_to_destroy.each do |place|
      target = Place.where({:_id => place }).first()
      puts "Destroying:" + target.name
      target.destroy
    end
  end
  
  def self.down
  end
end