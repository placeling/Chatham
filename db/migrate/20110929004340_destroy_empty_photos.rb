class DestroyEmptyPhotos < Mongoid::Migration
  def self.up
    for perspective in Perspective.all
        for picture in perspective.pictures
          if picture['image_filename'].nil?
            perspective.pictures.where( :_id =>picture.id ).delete_all
            puts "destroying #{picture.id} on perspective for #{perspective.place.name}"
          end
        end
    end
  end

  def self.down
  end
end