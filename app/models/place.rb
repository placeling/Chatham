require 'google_places'
require 'google_reverse_geocode'

class Place
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Mongoid::Slug
  include ApplicationHelper

  before_validation :fix_location, :remove_blank_categories, :parse_address

  field :loc, :as => :location, :type => Array
  field :name, :type => String
  field :gid, :as => :google_id, :type => String
  field :vicinity, :type => String
  field :street_address, :type => String
  field :phone_number, :type => String
  field :city_data, :type => String
  field :accurate_address, :type => Boolean, :default => false

  field :venue_types, :type => Array
  field :google_url, :type => String
  field :place_type, :type => String
  field :venue_url, :type => String
  field :pc, :as => :perspective_count, :type => Integer, :default => 0 #property for easier lookup of of top places

  field :google_ref, :type => String # may need this later, makes easier
  field :address_components, :type => Hash #save for later
  field :ptg, :as => :place_tags, :type => Array
  field :place_tags_last_update, :type => DateTime

  slug :name, :index => true, :permanent => true

  has_many :perspectives, :foreign_key => 'plid'
  belongs_to :client_application, :foreign_key => 'cid' #indexes on these don't seem as important
  belongs_to :user #not really that significant

  attr_accessor :users_bookmarking #transient property, shows people following
  attr_accessor :distance #transient property, shows distance to current location
  attr_accessor :placemarks #perspectives we want to attach to the return value

  validates_uniqueness_of :google_id, :allow_nil => true
  validates_presence_of :name
  validates_presence_of :venue_types, :message => " blank. You need to pick a category for this place "
  validates_presence_of :location

  index [[:loc, Mongo::GEO2D]], :min => -180, :max => 180
  index :ptg, :background => true
  index :gid
  index :pc


  def self.forgiving_find(place_id)
    if BSON::ObjectId.legal?(place_id)
      #it's a direct request for a place in our db
      place = Place.find(place_id)
    else
      place = Place.find_by_slug place_id
      if place.nil?
        place = Place.find_by_google_id(place_id)
      end
    end
    return place
  end

  def self.find_random(lat, long)
    places = Place.near(:loc => [lat, long]).
        and(:pc.gte => 1).
        limit(100)

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
        if tag_tally.has_key?(tag)
          tag_tally[tag] +=1
        else
          tag_tally[tag] =1
        end
      end
    end

    sorted_tag_tally = tag_tally.sort_by { |key, value| value }

    self.place_tags = sorted_tag_tally.last(n).collect! { |value| value[0] }

  end

  def remove_blank_categories
    self.venue_types.delete_if { |x| x == "" }
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
    if self.location[0] == 0.0 and self.location[1] == 0.0
      errors.add(:base, "You didn't include a latitude and longitude")
    end
  end

  def thumb_url
    for type in self.venue_types
      if type.downcase != "establishment"
        category = type
        break
      end
    end

    if !category
      return "#{ApplicationHelper.get_hostname}#{ActionController::Base.helpers.asset_path("quickpicks/EverythingPick.png")}"
    end

    if CATEGORIES["Bars & Nightlife"].keys().include?(category) or CATEGORIES["Bars & Nightlife"].values().include?(category)
      return "#{ApplicationHelper.get_hostname}#{ActionController::Base.helpers.asset_path("quickpicks/NightLifePick.png")}"
    elsif CATEGORIES["Government"].keys().include?(category) or CATEGORIES["Government"].values().include?(category)
      return "#{ApplicationHelper.get_hostname}#{ActionController::Base.helpers.asset_path("quickpicks/GovernmentPick.png")}"
    elsif CATEGORIES["Shopping"].keys().include?(category) or CATEGORIES["Shopping"].values().include?(category)
      return "#{ApplicationHelper.get_hostname}#{ActionController::Base.helpers.asset_path("quickpicks/ShoppingPick.png")}"
    elsif CATEGORIES["Beauty"].keys().include?(category) or CATEGORIES["Beauty"].values().include?(category)
      return "#{ApplicationHelper.get_hostname}#{ActionController::Base.helpers.asset_path("quickpicks/BeautyPick.png")}"
    elsif CATEGORIES["Interesting & Outdoors"].keys().include?(category) or CATEGORIES["Interesting & Outdoors"].values().include?(category)
      return "#{ApplicationHelper.get_hostname}#{ActionController::Base.helpers.asset_path("quickpicks/TouristyPick.png")}"
    elsif CATEGORIES["Restaurants & Food"].keys().include?(category) or CATEGORIES["Restaurants & Food"].values().include?(category)
      return "#{ApplicationHelper.get_hostname}#{ActionController::Base.helpers.asset_path("quickpicks/FoodPick.png")}"
    else
      return "#{ApplicationHelper.get_hostname}#{ActionController::Base.helpers.asset_path("quickpicks/EverythingPick.png")}"

      #elsif CATEGORIES["Services"].values().include?(category)
      #elsif CATEGORIES["Travel & Lodging"].values().include?(category)
      #elsif CATEGORIES["Religion"].values().include?(category)
      #elsif CATEGORIES["Health"].values().include?(category)

    end
  end

  def self.nearby_for_user(user, lat, long, span)
    n = CHATHAM_CONFIG['max_returned_map']

    #this is only necessary for ruby 1.8 since its hash doesn't preserve order, and mongodb requires it
    perspectives = Perspective.where(:uid => user.id).
        and(:ploc.within => {"$center" => [[lat, long], span]})

    places = []
    for perspective in perspectives
      places << perspective.place
    end

    return places
  end

  def self.all_near(lat, long, span)

    #this is only necessary for ruby 1.8 since its hash doesn't preserve order, and mongodb requires it
    Place.where(:loc.within => {"$center" => [[lat, long], span]}).
        and(:pc.gte => 1).
        order_by([:pc, :desc])
  end

  def self.find_by_categories(lat, long, span, categories_array)
    Place.any_in(:venue_types => categories_array).
        and(:loc.within => {"$center" => [[lat, long], span]})
  end

  def self.top_places(top_n)
    self.desc(:pc).limit(top_n)
  end

  def self.find_by_google_id(google_id)
    Place.where(:gid => google_id).first
  end

  def parse_address
    if self.address_components && !self.street_address && !self.city_data
      if self.address_components.is_a?(Hash)
        components_mash = Hashie::Mash.new(response)
      else
        if self.address_components.first.is_a?(Hash)
          components_mash = self.address_components.map { |item| Hashie::Mash.new(item) }
        else
          components_mash = {}
        end
      end

      address_dict = GooglePlaces.getAddressDict(components_mash)

      if address_dict['number'] and address_dict['street']
        self.street_address = address_dict['number'] + " " + address_dict['street']
      elsif address_dict['street']
        self.street_address = address_dict['street']
      end

      if address_dict['city'] and address_dict['province']
        self.city_data = address_dict['city'] + ", " + address_dict['province']
      end

    end
  end

  def self.new_from_google_place(raw_place)
    place = Place.new
    place.update_from_google_place(raw_place)
    return place
  end


  def update_from_google_place(raw_place)

    self.name = raw_place.name
    self.google_id = raw_place.id
    self.google_url = raw_place.url
    self.vicinity = raw_place.vicinity
    self.location = [raw_place.geometry.location.lat, raw_place.geometry.location.lng]
    self.address_components = raw_place.address_components unless raw_place.address_components.nil?
    self.phone_number = raw_place.formatted_phone_number unless raw_place.formatted_phone_number.nil?
    self.google_ref = raw_place.reference
    self.venue_url = raw_place.url unless raw_place.url.nil?

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

    self.venue_types = clean_venues

    self.place_type = "GOOGLE_PLACE"

    return self
  end


  def map_url
    "http://maps.google.com/maps/api/staticmap?center=#{loc[0]+0.0003},#{loc[1]}&zoom=15&size=100x100&&markers=icon:http://www.placeling.com/images/marker.png%7Ccolor:red%7C#{loc[0]},#{loc[1]}&sensor=false"
  end

  def wide_map_url
    "https://maps.google.com/maps/api/staticmap?center=#{loc[0]},#{loc[1]}&zoom=14&size=486x150&&markers=icon:http://www.placeling.com/images/marker.png%%7Ccolor:red%%7C#{loc[0]},#{loc[1]}&sensor=false"
  end

  def place_page_map_url
    "https://maps.google.com/maps/api/staticmap?center=#{loc[0]},#{loc[1]}&zoom=14&size=292x92&&markers=icon:http://www.placeling.com/images/marker.png%%7Ccolor:red%%7C#{loc[0]},#{loc[1]}&sensor=false"
  end

  def self.new_from_user_input(place, radius=10)
    gp = GooglePlaces.new

    # TODO This is hacky and ignores i18n
    @categories = CATEGORIES

    google_mapping = {}
    @categories.each do |category, components|
      components.each do |key, value|
        google_mapping[key] = value
      end
    end

    venue_type = google_mapping[place.venue_types[0]] || place.venue_types[0]

    unless !Rails.env.production?
      raw_place = gp.create(place.location[0], place.location[1], radius, place.name, venue_type)
      grg = GoogleReverseGeocode.new
      raw_address = grg.reverse_geocode(place.location[0], place.location[1])
      place.google_id = raw_place.id
      place.google_ref = raw_place.reference
    end
    place.place_type = "USER_CREATED"

    return place
  end

  def og_path
    "#{ApplicationHelper.get_hostname}#{ Rails.application.routes.url_helpers.place_path(self) }"
  end

  def as_json(options={})
    self.venue_types.delete("Establishment") #filter out establishment from return values

    attributes = {
        :id => self['_id'],
        :_id => self['_id'],
        :name => self['name'],
        :lat => self.location[0],
        :lng => self.location[1],
        :street_address => self.street_address,
        :city_data => self.city_data,
        :location => self.location,
        :tags => self.tags,
        :google_id => self['gid'],
        :google_ref => self.google_ref,
        :google_url => self.google_url,
        :perspective_count => self['pc'],
        :thumb_url => self.thumb_url,
        :map_url => self.map_url,
        :venue_types => self.venue_types
    }

    attributes = attributes.merge(:users_bookmarking => self.users_bookmarking) unless self.users_bookmarking.nil?
    attributes = attributes.merge(:placemarks => self.placemarks.as_json({:current_user => options[:current_user], :place_view => true}))

    if options[:bounds]
      attributes.delete(:lat)
      attributes.delete(:lng)
      attributes.delete(:street_address)
      attributes.delete(:google_id)
      attributes.delete(:google_ref)
      attributes.delete(:google_url)
      attributes.delete(:thumb_url)
      attributes.delete(:map_url)
      attributes.delete(:perspective_count)
      attributes.delete(:city_data)
    end

    if options[:current_user]
      current_user = options[:current_user]
      bookmarked = self.perspectives.where(:uid => current_user.id).count >0
      attributes = attributes.merge(:bookmarked => bookmarked)

      attributes = attributes.merge(:following_perspective_count => self.perspectives.where(:uid.in => current_user.following_ids).count)
      attributes[:highlighted] = current_user.highlighted?(self)

      if options[:detail_view] == true
        @home_perspectives = [] #perspectives to be returned in detail view
        perspective = current_user.perspectives.where(:plid => self.id).first
        @home_perspectives << perspective unless perspective.nil?

        user_perspective = current_user.perspective_for_place(self)
        @starred = []
        @starred = user_perspective.favourite_perspectives unless user_perspective.nil?

        #@starred = self.perspectives.where(:_id.in => current_user.favourite_perspectives).excludes(:uid => current_user.id)
        @home_perspectives.concat(@starred)
        attributes = attributes.merge(:perspectives => @home_perspectives.as_json({:current_user => current_user, :place_view => true}))
      end
    end

    if options[:referring_user]
      referring_user = options[:referring_user]

      @referring_perspectives = [] #perspectives to be returned in detail view

      perspective = referring_user.perspective_for_place(self)
      @referring_perspectives << perspective unless perspective.nil?

      @starred = []
      @starred = perspective.favourite_perspectives unless perspective.nil?

      # @starred = self.perspectives.where(:_id.in => referring_user.favourite_perspectives).excludes(:uid => referring_user.id)
      @referring_perspectives.concat(@starred)

      attributes = attributes.merge(:referring_perspectives => @referring_perspectives.as_json({:current_user => current_user, :place_view => true}))
    end

    return attributes

  end

end
