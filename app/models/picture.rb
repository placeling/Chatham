class Picture
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  mount_uploader :image, PictureUploader

  embedded_in :perspective


  def as_json(options={})
    attributes = self.attributes.merge(:photos =>pictures)

    if options[:current_user]
      current_user = options[:current_user]

      if current_user.id ==  self.perspective[:uid]
        attributes = attributes.merge(:mine => true)
      else
        attributes = attributes.merge(:mine => false)
      end
    end
  end
end