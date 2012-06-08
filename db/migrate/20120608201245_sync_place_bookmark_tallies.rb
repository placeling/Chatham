class SyncPlaceBookmarkTallies < Mongoid::Migration
  def self.up
    i=0
    Place.all.each do |place|
      if place[:pc] != place.perspectives.count
        puts place.name
        place.perspective_count = place.perspectives.count
        place.save!
        i = i +1
      end
    end
    puts "Updated #{i} places"
  end

  def self.down
  end
end