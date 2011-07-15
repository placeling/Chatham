class Place
  include Mongoid::Document
  include Mongoid::Timestamps

  field :location, :type => Array
  field :name, :type => String
  field :google_place_id, :type => String
  field :vicinity, :type => String
  field :venue_types, :type => Array

  has_many :perspectives

  index [[ :location, Mongo::GEO2D ]], :min => -180, :max => 180
  index :google_place_id



  #Address.near(:latlng => [37.761523, -122.423575, 1])

end
