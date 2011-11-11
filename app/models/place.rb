require 'google_places'
require 'google_reverse_geocode'

class Place
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  
  before_validation :fix_location
  
  field :loc, :as => :location, :type => Array
  field :name, :type => String
  field :gid, :as => :google_id, :type => String
  field :vicinity, :type => String
  field :street_address, :type => String
  field :phone_number, :type => String
  field :city_data, :type => String

  field :venue_types, :type => Array
  field :google_url,  :type => String
  field :place_type,  :type => String
  field :pc, :as => :perspective_count, :type => Integer, :default => 0 #property for easier lookup of of top places

  field :google_ref,  :type => String # may need this later, makes easier
  field :address_components, :type => Hash #save for later
  field :ptg, :as => :place_tags, :type => Array
  field :place_tags_last_update, :type => DateTime

  has_many :perspectives, :foreign_key => 'plid'
  belongs_to :client_application, :foreign_key => 'cid' #indexes on these don't seem as important
  belongs_to  :user #not really that significant

  attr_accessor :users_bookmarking #transient property, shows people following
  attr_accessor :distance #transient property, shows distance to current location

  validates_uniqueness_of :google_id, :allow_nil =>true
  validates :name, :venue_types, :presence => true

  index [[ :loc, Mongo::GEO2D ]], :min => -180, :max => 180
  index :ptg, :background => true
  index :gid
  index :pc

  def self.find_random(lat, long)
    places = Place.near(:loc => [lat,long]).
        and(:pc.gte => 1).
        limit( 100 )

    if places.count > 0
      i = rand(places.size)
      return places[i]
    else
      return nil
    end
  end

  def tags
    t = CHATHAM_CONFIG['cache_tags_time_hours'].to_i

    if self.place_tags_last_update.nil? or self.place_tags_last_update < t.hour.ago
      #cache these for t hours
      self.place_tags_last_update = Time.now
      update_tags
    end

    return self.place_tags
  end

  def update_tags
    return unless !self.perspectives.nil?
    n = CHATHAM_CONFIG['num_top_tags']

    tag_tally = {}

    for perspective in self.perspectives
      next unless !perspective.tags.nil?
      for tag in perspective.tags
        if tag_tally.has_key?( tag )
          tag_tally[tag] +=1
        else
          tag_tally[tag] =1
        end
      end
    end

    sorted_tag_tally = tag_tally.sort_by {|key, value| value}

    self.place_tags = sorted_tag_tally.last( n ).collect!{|value| value[0]}

  end
  
  def fix_location
    begin
      if self.location[0].is_a? String
        self.location[0] = self.location[0].to_f
      end
      if self.location[1].is_a? String
        self.location[1] = self.location[1].to_f
      end
    rescue
      errors.add(:base, "You didn't include a latitude and longitude")
    end
    if self.location[0] == 0.0 and self.location[1] == 0.0:
      errors.add(:base, "You didn't include a latitude and longitude")
    end
  end

  def self.nearby_for_user( user, lat, long, span )
    n = CHATHAM_CONFIG['max_returned_map']

    #this is only necessary for ruby 1.8 since its hash doesn't preserve order, and mongodb requires it
    perspectives = Perspective.where(:ploc.within => {"$center" => [[lat,long],span]}).
        and(:uid => user.id).
        limit( n )

    places = []
    for perspective in perspectives
      places << perspective.place
    end

    return places
  end

  def self.all_near( lat, long, span )

    #this is only necessary for ruby 1.8 since its hash doesn't preserve order, and mongodb requires it
    Place.where(:loc.within => {"$center" => [[lat,long],span]}).
        and(:pc.gte => 1).
        order_by([:pc, :desc])
  end

  def self.find_by_categories( lat, long, span, categories_array )
    Place.any_in(:venue_types => categories_array ).
        and(:loc.within => {"$center" => [[lat,long],span]})
  end

  def self.top_places( top_n )
    self.desc( :pc ).limit( top_n )
  end

  def self.find_by_google_id( google_id )
    Place.where(:gid => google_id).first
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

    if raw_place.address_components
      if raw_place.address_components.length > 3
        #TODO: find out how this scales past north america
        place.city_data = raw_place.address_components[2].short_name + ", " + raw_place.address_components[3].short_name
      end

      if raw_place.address_components.length > 1
        #TODO: find out how this scales past north america
        place.street_address = raw_place.address_components[0].short_name + " " + raw_place.address_components[1].short_name
      end
      place.address_components = raw_place.address_components
    end
    
    # TODO This is hacky and ignores i18n
    @categories = CATEGORIES
    
    friendly_mapping = {}
    @categories.each do |category, components|
      components.each do |key, value|
        # multiple items map to "other" so skip it
        if value != "other"
          friendly_mapping[value] = key
        end
      end
    end
    
    clean_venues = []
    raw_place.types.each do |venue|
      # skip other as no value in showing "other" to user. WTF does "other" mean?
      if venue != "other"
        if friendly_mapping.has_key?(venue)
          clean_venues.push(friendly_mapping[venue])
        else
          pieces = venue.split("_")
          new_pieces = []
          pieces.each do |piece|
            new_pieces.push(piece.capitalize)
          end
          clean_venues.push(new_pieces.join(" "))
        end
      end
    end
    
    place.venue_types = clean_venues
    
    place.place_type = "GOOGLE_PLACE"

    return place
  end

  def self.new_from_user_input( old_place, radius=10 )
    gp = GooglePlaces.new
    
    # TODO This is hacky and ignores i18n
    @categories = CATEGORIES
    
    google_mapping = {}
    @categories.each do |category, components|
      components.each do |key, value|
        google_mapping[key] = value
      end
    end
    
    venue_type = google_mapping[old_place.venue_types[0]]
    
    raw_place = gp.create(old_place.location[0], old_place.location[1], radius, old_place.name, venue_type)
    
    grg = GoogleReverseGeocode.new
    
    raw_address = grg.reverse_geocode(old_place.location[0], old_place.location[1])
    
    place = Place.new
    
    place.name = old_place.name
    place.google_id = raw_place.id
    place.location = old_place.location
    
    place.google_ref = raw_place.reference
    
    place.venue_types = old_place.venue_types
    place.place_type = "USER_CREATED"
    
    if !raw_address.nil?
      street_number = nil
      route = nil
      locality = nil
      admin_area_level_1 = nil
      
      raw_address.address_components.each do |component|
        if component["types"].include? "street_number"
          street_number = component["short_name"]
        end
        if component["types"].include? "route"
          route = component["short_name"]
        end
        if component["types"].include? "locality"
          locality = component["long_name"]
        end
        if component["types"].include? "administrative_area_level_1"
          admin_area_level_1 = component["short_name"]
        end
      end
      
      if !street_number.nil? and !route.nil?
        place.address_components = street_number + " " + route
      elsif street_number.nil? and !route.nil?
        place.address_components = route
      end
      
      if !locality.nil? and !admin_area_level_1.nil?
        place.city_data = locality + ", " + admin_area_level_1
      elsif locality.nil? and !admin_area_level_1.nil?
        place.city_data = admin_area_level_1
      end
    end
    
    return place
  end
  
  def as_json(options={})
    attributes = self.attributes.merge(:tags => self.tags)
    attributes = attributes.merge(:users_bookmarking => self.users_bookmarking) unless self.users_bookmarking.nil?

    attributes.delete(:google_ref)
    attributes.delete(:address_components)
    attributes.delete(:client_application_id)
    attributes.delete(:place_tags_last_update)
    attributes[:location] = attributes.delete('loc')
    attributes[:place_tags] = attributes.delete('ptg')
    attributes[:google_id] = attributes.delete('gid')
    attributes[:perspective_count] = attributes.delete('pc')

    if options[:current_user]
      current_user = options[:current_user]
      bookmarked = self.perspectives.where(:uid=> current_user.id).count >0
      attributes = attributes.merge(:bookmarked => bookmarked)

      attributes = attributes.merge(:following_perspective_count => self.perspectives.where(:uid.in => current_user.following_ids).count)

      @home_perspectives = [] #perspectives to be returned in detail view
      perspective = current_user.perspectives.where( :plid => self.id ).first
      @home_perspectives << perspective unless perspective.nil?

      @starred = self.perspectives.where(:_id.in => current_user.favourite_perspectives).excludes(:uid => current_user.id)
      @home_perspectives.concat( @starred )

      attributes = attributes.merge( :perspectives => @home_perspectives.as_json( {:current_user => current_user, :place_view=>true} ) )
    end

    if options[:referring_user]
      referring_user = options[:referring_user]

      @referring_perspectives = [] #perspectives to be returned in detail view

      perspective = referring_user.perspectives.where( :plid => self.id ).first
      @referring_perspectives << perspective unless perspective.nil?

      @starred = self.perspectives.where(:_id.in => referring_user.favourite_perspectives).excludes(:uid => referring_user.id)
      @referring_perspectives.concat( @starred )

      attributes = attributes.merge( :referring_perspectives => @referring_perspectives.as_json( {:current_user => current_user, :place_view=>true} ) )
    end

    if options[:detail_view] == true
      attributes.merge(:user => user)
    else
      attributes
    end

  end

end
