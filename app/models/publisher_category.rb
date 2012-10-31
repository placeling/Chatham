class PublisherCategory
  include Mongoid::Document
  include Mongoid::Slug

  field :name, :type => String
  field :tags, :type => String
  field :filename, :type => String

  embedded_in :publisher

  slug :name, :permanent => true


end