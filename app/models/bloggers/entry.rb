class Entry
  include Mongoid::Document
  include Mongoid::Timestamps

  field :url, :type => String
  field :title, :type => String
  field :content, :type => String
  field :slug

  field :places, :type => Array, :default => []


  embedded_in :bloggers_blogger, :class_name => 'Bloggers::Blogger'
end