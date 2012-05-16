class CreateMosaicImages < Mongoid::Migration
  def self.up
    Perspective.all.each do |perp|
      perp.pictures.each do |picture|
        if picture.creation_environment == Rails.env
          puts "Recreating picture for #{perp.user.username}'s perspctive on #{perp.place.name}'"
          picture.image.recreate_versions!
        end
      end
    end
  end

  def self.down
  end
end