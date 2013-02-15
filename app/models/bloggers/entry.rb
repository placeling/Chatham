class Entry
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :guid, :type => String
  field :url, :type => String
  field :title, :type => String
  field :content, :type => String
  field :published, :type => DateTime
  field :slug

  field :location, :type => Array

  field :places, :type => Array, :default => []
  belongs_to :place

  embedded_in :bloggers_blogger, :class_name => 'Bloggers::Blogger'
end