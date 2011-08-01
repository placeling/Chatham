class Picture
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  mount_uploader :image, PictureUploader

  embedded_in :perspective

end