class PublisherCategory
  include Mongoid::Document
  include Mongoid::Slug

  field :name, :type => String

  field :module_type, :type => Integer, :default => 0
  field :tags, :type => String

  mount_uploader :image, CategoryUploader

  embedded_in :publisher

  slug :name, :permanent => true


end