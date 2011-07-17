class Place
  include Mongoid::Document
  include Mongoid::Timestamps

  field :location, :type => Hash
  field :name, :type => String
  field :google_id, :type => String
  field :vicinity, :type => String
  field :venue_types, :type => Array
  field :google_url,  :type => String

  embeds_many :perspectives
  #doesn't actually need to reference users, kind of contained not needing it

  index [[ :location, Mongo::GEO2D ]], :min => -180, :max => 180
  index :google_id
  index "perspectives.user_id"


  def self.find_by_google_id( google_id )
    Place.where(:google_id => google_id).first
  end

  def self.create_from_google_place( raw_place )
    place = Place.new do |p|
      p.name = raw_place.name
      p.google_id = raw_place.id
      p.google_url = raw_place.url
      p.vicinity = raw_place.vicinity
      p.location = {:x =>raw_place.geometry.location.lat, :y =>raw_place.geometry.location.lng}
      p.venue_types = raw_place.types
    end

    place.save
    return place
  end

  #Address.near(:latlng => [37.761523, -122.423575, 1])

end
