class Picture
  include Mongoid::Document
  include Mongoid::Timestamps

  field :creation_environment, :type => String
  field :thumb_cache_url, :type => String
  field :iphone_cache_url, :type => String
  field :main_cache_url, :type => String

  field :deleted, :type =>Boolean, :default => false

  mount_uploader :image, PictureUploader
  
  embedded_in :perspective

  #validates_presence_of :creation_environment, :on => :create
  after_save :more_test

  def more_test
    if self.changed?
      #added cache urls
      self.save
    end
  end

  def cache_urls
    self.thumb_cache_url = self.image_url(:thumb)
    self.iphone_cache_url = self.image_url(:iphone)
    self.main_cache_url =  self.image_url(:main)
  end

  def thumb_url
    if Rails.env == self.creation_environment
      self.image_url(:thumb)
    elsif thumb_cache_url
      thumb_cache_url
    else
      return "http://placeling.com/images/default_profile.png"
    end
  end

  def iphone_url
    if Rails.env == self.creation_environment
      self.image_url(:iphone)
    elsif iphone_cache_url
      iphone_cache_url
    else
      return "http://placeling.com/images/default_profile.png"
    end
  end

  def main_url
    if Rails.env == self.creation_environment
      self.image_url(:main)
    elsif main_cache_url
      main_cache_url
    else
      return "http://placeling.com/images/default_profile.png"
    end
  end


  def as_json(options={})
    attributes = self.attributes
    #TODO: reset thumb_url to iphone_url after NINA 1.2 fix
    attributes = attributes.merge(:thumb_url => self.iphone_url,
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