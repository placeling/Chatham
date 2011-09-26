class Picture
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessible :image, :title

  field :title, :type => String
  mount_uploader :image, PictureUploader
  
  embedded_in :perspective

  def as_json(options={})
    attributes = self.attributes
    attributes = attributes.merge(:thumb_url => self.image_url(:thumb),
                                    :iphone_url => self.image_url(:iphone),
                                    :main_url => self.image_url(:main))

    if options[:current_user] && options[:current_user].id == self.perspective[:uid]
      attributes = attributes.merge(:mine => true)
    else
      attributes = attributes.merge(:mine => false)
    end
    attributes
  end
end