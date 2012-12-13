class PublisherCategory
  include Mongoid::Document
  include Mongoid::Slug

  field :name, :type => String

  field :module_type, :type => Integer, :default => 0
  field :tags, :type => String

  field :creation_environment, :type => String
  field :main_cache_url, :type => String
  field :thumb_cache_url, :type => String
  field :file_size, :type => Integer

  mount_uploader :image, CategoryUploader

  embedded_in :publisher

  slug :name, :permanent => true, :scope => :publisher

  #url_cache [:main, :thumb]

  def image=(obj)
    super(obj)
    # Put your callbacks here, e.g.
    self.file_size = image.size
    self.creation_environment = nil
    self.main_cache_url = nil
    self.thumb_cache_url = nil
  end


  def cache_urls
    self.creation_environment = Rails.env
    self.main_cache_url = self.image_url(:main)
    self.thumb_cache_url = self.image_url(:thumb)
    self.save
  end

  def main_url
    if Rails.env == self.creation_environment
      self.image_url(:main)
    elsif main_cache_url
      main_cache_url
    else
      self.cache_urls
      self.image_url(:main)
    end
  end

  def thumb_url
    if Rails.env == self.creation_environment
      self.image_url(:thumb)
    elsif thumb_cache_url
      thumb_cache_url
    else
      self.cache_urls
      self.image_url(:thumb)
    end
  end

  def as_json(options={})
    self.attributes.merge(:image_url => self.main_url).merge(:thumb_url => self.thumb_url)
  end

end