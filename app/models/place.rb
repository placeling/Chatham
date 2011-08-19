class Place
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia

  before_validation :fix_location

  field :location, :type => Array
  field :name, :type => String
  field :google_id, :type => String
  field :vicinity, :type => String
  field :street_address, :type => String
  field :phone_number, :type => String

  field :venue_types, :type => Array
  field :google_url,  :type => String
  field :place_type,  :type => String
  field :perspective_count, :type => Integer, :default => 0 #property for easier lookup of of top places

  field :google_ref,  :type => String # may need this later, makes easier
  field :address_components, :type => Hash #save for later

  has_many :perspectives
  belongs_to :client_application
  belongs_to :user

  index [[ :location, Mongo::GEO2D ]], :min => -180, :max => 180
  index :google_id
  index :perspective_count


  def fix_location
    if self.location[0].is_a? String
      self.location[0] = self.location[0].to_f
    end
    if self.location[1].is_a? String
      self.location[1] = self.location[1].to_f
    end
  end

  def self.top_places( top_n )
    self.desc( :perspective_count ).limit( top_n )
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

    place.phone_number = raw_place.formatted_phone_number unless !raw_place.formatted_phone_number?
    place.google_ref = raw_place.reference
    if raw_place.address_components.length > 1
      #TODO: find out how this scales past north america
      place.street_address = raw_place.address_components[0].short_name + " " + raw_place.address_components[1].short_name
    end
    place.address_components = raw_place.address_components

    place.venue_types = raw_place.types
    place.place_type = "GOOGLE_PLACE"

    return place
  end


  def self.new_from_user_input( params )
    params[:location] = [params[:lat], params[:long]]
    place = Place.new( params )
    place.place_type = "USER_CREATED"
    return place
  end

  def as_json(options={})
    attributes = self.attributes
    attributes.delete(:google_ref)
    attributes.delete(:address_components)
    attributes.delete(:client_application_id)

    if options[:detail_view] == true
      if options && options[:current_user]
        bookmarked = self.perspectives.where(:user_id=> options[:current_user].id).count >0
        attributes = attributes.merge(:bookmarked => bookmarked)
      end

      attributes.merge(:user => user)
    else
      attributes
    end

  end

end
