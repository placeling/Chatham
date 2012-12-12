class PublisherCategory
  include Mongoid::Document
  include Mongoid::Slug

  field :name, :type => String

  field :module_type, :type => Integer, :default => 0
  field :tags, :type => String

  field :creation_environment, :type => String
  field :main_cache_url, :type => String

  before_save :cache_urls

  def cache_urls
    if self.creation_environment.nil?
      self.creation_environment = Rails.env
      self.main_cache_url = self.image_url(:main)
    end
  end

  def main_url
    if Rails.env == self.creation_environment
      self.image_url(:main)
    elsif main_cache_url
      main_cache_url
    else
      self.image_url(:main)
    end
  end

  mount_uploader :image, CategoryUploader

  embedded_in :publisher

  slug :name, :permanent => true


  def as_json(options={})
    self.attributes.merge(:image_url => self.main_url)
  end

end