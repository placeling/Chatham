class Picture
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps

  field :creation_environment, :type => String
  field :thumb_cache_url, :type => String
  field :iphone_cache_url, :type => String
  field :main_cache_url, :type => String

  mount_uploader :image, PictureUploader
  
  embedded_in :perspective

  before_validation :set_creation_environment
  after_create :cache_urls

  validates_presence_of :creation_environment, :on => :create

  def set_creation_environment
    self.creation_environment = Rails.env unless !self.creation_environment.nil?
  end

  def cache_urls
    self.thumb_cache_url = self.image_url(:thumb)
    self.iphone_cache_url = self.image_url(:iphone)
    self.main_cache_url =  self.image_url(:main)
    self.save
  end

  def thumb_url
    if Rails.env == self.creation_environment
      return self.image_url(:thumb)
    else
      return thumb_cache_url
    end
  end

  def iphone_url
    if Rails.env == self.creation_environment
      return self.image_url(:iphone)
    else
      return iphone_cache_url
    end
  end

  def main_url
    if Rails.env == self.creation_environment
      return self.image_url(:main)
    else
      return main_cache_url
    end
  end


  def as_json(options={})
    attributes = self.attributes
    attributes = attributes.merge(:thumb_url => self.thumb_url,
                                    :iphone_url => self.iphone_url,
                                    :main_url => self.main_url)
    attributes.delete('creation_environment')
    attributes.delete('thumb_cache_url')
    attributes.delete('iphone_cache_url')
    attributes.delete('main_cache_url')

    if options[:current_user] && options[:current_user].id == self.perspective[:uid]
      attributes = attributes.merge(:mine => true)
    else
      attributes = attributes.merge(:mine => false)
    end
    attributes
  end
end