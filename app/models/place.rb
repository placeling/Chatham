class Place
  include Mongoid::Document
  include Mongoid::Timestamps
  before_validation :fix_location

  field :location, :type => Array
  field :name, :type => String
  field :google_id, :type => String
  field :vicinity, :type => String
  field :venue_types, :type => Array
  field :google_url,  :type => String
  field :place_type,  :type => String

  has_many :perspectives
  belongs_to :user

  index [[ :location, Mongo::GEO2D ]], :min => -180, :max => 180
  index :google_id


  def fix_location
    if self.location[0].is_a? String
      self.location[0] = self.location[0].to_f
    end
    if self.location[1].is_a? String
      self.location[1] = self.location[1].to_f
    end
  end

  def self.find_by_google_id( google_id )
    Place.where(:google_id => google_id).first
  end

  def self.new_from_google_place( raw_place )
    place = Place.new
    place.name = raw_place.name
    place.google_id = raw_place.id
    place.google_url = raw_place.url
    place.vicinity = raw_place.vicinity
    place.location = [raw_place.geometry.location.lat, raw_place.geometry.location.lng]
    place.venue_types = raw_place.types
    place.place_type = "GOOGLE_PLACE"

    return place
  end


  def self.new_from_user_input( params )
    place = Place.new( params )
    place.place_type = "USER_CREATED"
    return place
  end

  #Address.near(:latlng => [37.761523, -122.423575, 1])

end
