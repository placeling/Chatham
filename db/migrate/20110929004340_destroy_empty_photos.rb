class DestroyEmptyPhotos < Mongoid::Migration
  def self.up
    for perspective in Perspective.all
      if perspective.pictures
        for picture in perspective.pictures
          if picture.main_cache_url.nil?
            picture.destroy
          end
        end
      end
    end
  end

  def self.down
  end
end