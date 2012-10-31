class PublisherCategory
  include Mongoid::Document

  field :name, :type => String
  field :tags, :type => String
  field :filename, :type => String

  embedded_in :publisher


end