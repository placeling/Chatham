class Picture
  include Mongoid::Document
  include Mongoid::Timestamps
  include ApplicationHelper

  field :creation_environment, :type => String
  field :thumb_cache_url, :type => String
  field :iphone_cache_url, :type => String
  field :main_cache_url, :type => String
  field :mosaic_3_1_cache_url, :type => String # 3 column layout, 1 column wide, 132px x 132px, 9px border
  field :mosaic_3_2_cache_url, :type => String # 3 column layout, 2 columns wide, 282px x 132px, 9px border
  field :mosaic_3_3_cache_url, :type => String # 3 column layout, 3 columns wide, 432px x 282px, 9px border

  field :remote_url, :type => String

  field :deleted, :type =>Boolean, :default => false
  field :fb_posted, :type =>Boolean, :default => false

  mount_uploader :image, PictureUploader, mount_on: :image_filename
  
  embedded_in :perspective

  #validates_presence_of :creation_environment, :on => :create
  before_save :cache_urls

  def cache_urls
    if !self.creation_environment
      self.creation_environment = Rails.env
      self.thumb_cache_url = self.image_url(:thumb)
      self.iphone_cache_url = self.image_url(:iphone)
      self.main_cache_url =  self.image_url(:main)
      self.mosaic_3_1_cache_url = self.image_url(:mosaic_3_1)
      self.mosaic_3_2_cache_url = self.image_url(:mosaic_3_2)
      self.mosaic_3_3_cache_url = self.image_url(:mosaic_3_3)
    end
  end
  
  def thumb_url
    if Rails.env == self.creation_environment
      self.image_url(:thumb)
    elsif thumb_cache_url
      thumb_cache_url
    else
      return "#{ApplicationHelper.get_hostname}/images/default_profile.png"
    end
  end

  def iphone_url
    if Rails.env == self.creation_environment
      self.image_url(:iphone)
    elsif iphone_cache_url
      iphone_cache_url
    else
      return "#{ApplicationHelper.get_hostname}/images/default_profile.png"
    end
  end

  def main_url( default = "#{ApplicationHelper.get_hostname}/images/default_profile.png")
    if Rails.env == self.creation_environment
      self.image_url(:main)
    elsif main_cache_url
      main_cache_url
    else
      return default
    end
  end
  
  def mosaic_3_1_url
    if Rails.env == self.creation_environment
      self.image_url(:mosaic_3_1)
    elsif mosaic_3_1_cache_url
      mosaic_3_1_cache_url
    else
      return "#{ApplicationHelper.get_hostname}/images/default_profile.png"
    end
  end
  
  def mosaic_3_2_url
    if Rails.env == self.creation_environment
      self.image_url(:mosaic_3_2)
    elsif mosaic_3_2_cache_url
      mosaic_3_2_cache_url
    else
      return "#{ApplicationHelper.get_hostname}/images/default_profile.png"
    end
  end
  
  def mosaic_3_3_url
    if Rails.env == self.creation_environment
      self.image_url(:mosaic_3_3)
    elsif mosaic_3_3_cache_url
      mosaic_3_3_cache_url
    else
      return "#{ApplicationHelper.get_hostname}/images/default_profile.png"
    end
  end
  
  def as_json(options={})
    attributes = {:id =>self['_id'], :_id => self['_id'] }

    #TODO: reset thumb_url to iphone_url after NINA 1.2 fix
    attributes = attributes.merge(:thumb_url => self.iphone_url,
                                    :iphone_url => self.iphone_url,
                                    :main_url => self.main_url,
                                    :square_url => self.mosaic_3_1_url)

    if options && options[:current_user] && options[:current_user].id == self.perspective[:uid]
      attributes = attributes.merge(:mine => true)
    else
      attributes = attributes.merge(:mine => false)
    end
    attributes
  end
end