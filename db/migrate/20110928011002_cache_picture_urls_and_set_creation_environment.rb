class CachePictureUrlsAndSetCreationEnvironment < Mongoid::Migration
  def self.up
    for perspective in Perspective.all
      for picture in perspective.pictures
        picture.set_creation_environment
        picture.cache_urls
      end
    end
  end

  def self.down

  end
end