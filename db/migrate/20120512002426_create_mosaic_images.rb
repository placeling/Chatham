class CreateMosaicImages < Mongoid::Migration
  def self.up
    Perspective.all.each do |perp|
      perp.pictures.each do |picture|
        begin
          if picture.creation_environment == Rails.env
            picture.image.cache_stored_file!
            picture.image.retrieve_from_cache!(picture.image.cache_name)
            
            puts "Recreating picture for #{perp.user.username}'s perspctive on #{perp.place.name}'"
            
            picture.image.recreate_versions!
            picture.save!
          end
        rescue => e
          puts  "ERROR: perspective #{perp.id}: picture #{picture.id} -> #{e.to_s}"
        end
      end
    end
  end

  def self.down
  end
end