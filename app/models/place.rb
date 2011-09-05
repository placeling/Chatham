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
  field :ptg, :as => :place_tags, :background => true
  field :place_tags_last_update, :type => DateTime

  has_many :perspectives
  belongs_to :client_application, :foreign_key => 'cid' #indexes on these don't seem as important
  belongs_to  :user, :foreign_key => 'uid'

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
    if self.location[0].is_a? String
      self.location[0] = self.location[0].to_f
    end
    if self.location[1].is_a? String
      self.location[1] = self.location[1].to_f
    end
  end

  def self.find_all_near( lat, long, radius )

    n = CHATHAM_CONFIG['max_returned_map']

    #this is only necessary for ruby 1.8 since its hash doesn't preserve order, and mongodb requires it
    Place.where(:loc.within => {"$center" => [[lat,long],radius]}).
        and(:pc.gte => 1).
        order_by([:pc, :desc]).
        limit( n )

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
    if raw_place.address_components.length > 3
      #TODO: find out how this scales past north america
      place.city_data = raw_place.address_components[2].short_name + ", " + raw_place.address_components[3].short_name
    end

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
    attributes = self.attributes.merge(:tags => self.tags)
    attributes.delete(:google_ref)
    attributes.delete(:address_components)
    attributes.delete(:client_application_id)
    attributes.delete(:ptg)
    attributes.delete(:place_tags_last_update)

    if options[:detail_view] == true
      if options && options[:current_user]
        current_user = options[:current_user]
        bookmarked = self.perspectives.where(:user_id=> current_user.id).count >0
        attributes = attributes.merge(:bookmarked => bookmarked)

        attributes = attributes.merge(:following_perspective_count => self.perspectives.where(:user_id.in => current_user.following_ids).count)

        @home_perspectives = [] #perspectives to be returned in detail view
        perspective = current_user.perspectives.where( :place_id => self.id ).first
        @home_perspectives << perspective unless perspective.nil?

        @starred = self.perspectives.where(:_id.in => current_user.favourite_perspectives).excludes(:user_id => current_user.id)
        @home_perspectives.concat( @starred )

        attributes = attributes.merge( :perspectives => @home_perspectives.as_json( {:current_user => current_user, :raw_view=>true} ) )
      end

      attributes.merge(:user => user)
    else
      attributes
    end

  end

end
