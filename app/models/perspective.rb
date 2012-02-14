require 'google_places'

class Perspective
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Twitter::Extractor

  field :memo,        :type => String
  field :tags,    :type => Array
  field :url,       :type => String
  field :flag_count, :type => Integer, :default =>0
    
  #these are meant for internal use, not immediately visible to user -iMack
  field :loc, :as => :location,    :type => Array
  field :ploc, :as => :place_location,    :type => Array
  field :flaggers, :type =>Array
  field :accuracy,      :type => Float

  #contains starred perspectives this user has of on the place
  field :fp, :as => :favourite_perspective_ids,    :type => Array, :default =>[]
  field :su, :as => :starring_users, :type =>Array, :default =>[]

  belongs_to :place, :foreign_key => 'plid', :index =>true
  belongs_to :user, :foreign_key => 'uid', :index =>true
  belongs_to :client_application

  embeds_many :pictures
  embeds_one :place_stub

  accepts_nested_attributes_for :pictures, :allow_destroy => true, :reject_if => lambda { |a| a[:content].blank? }

  index [[ "place_stub.loc", Mongo::GEO2D ]], :min => -180, :max => 180
  index [[ :ploc, Mongo::GEO2D ]], :min => -180, :max => 180
  index [[ :loc, Mongo::GEO2D ]], :min => -180, :max => 180
  index "place_stub.venue_types"
  index "place_stub.ptg"
  index :tags, :background => true

  validates_associated :place
  validates_associated :user

  validates :url, :format => { :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,
      :message => "Invalid URL" }

  before_validation :fix_location
  before_save :get_place_data
  before_save :parse_tags
  after_save :reset_user_and_place_perspective_count
  after_destroy :reset_user_and_place_perspective_count
  after_create :check_in
  before_create :notify_feed_create
  before_update :notify_feed_update
  before_destroy :scrub_stars

  attr_accessor :skip_feed

  def self.find_recent_for_user( user, start, count )
    Perspective.where(:uid => user.id).
        order_by( [:created_at, :desc] ).
        skip( start ).
        limit( count ).
        entries
  end

  def self.query_near( loc, span,  query, category )
    geonear = BSON::OrderedHash.new()
    geonear["$near"] = loc
    geonear["$maxDistance"] = span

    selector = Perspective.where( :ploc => geonear )

    if category != nil and category.strip != ""
      categories_array = CATEGORIES[category].keys + CATEGORIES[category].values
      selector = selector.any_in("place_stub.venue_types" => categories_array)
    end

    if query != nil and query.strip != ""
      tags = Perspective.extract_tag_array( query.downcase.strip )
      selector = selector.any_in(:tags => tags)
    end

    return selector
  end

  def check_in
    if self.place.google_id and Rails.env.production?
      gp = GooglePlaces.new
      begin
        output = gp.check_in(self.place.google_id)
      rescue
        #don't fail just because we can't reach google
      end
    end
  end

  def scrub_stars
    user = self.user
    for perspective in self.favourite_perspective_ids
      perspective.starring_users.delete( user.id )
    end
  end

  def notify_feed_create
    ActivityFeed.add_new_perspective(self.user, self) unless self.skip_feed
  end

  def notify_feed_update
    ActivityFeed.add_update_perspective(self.user, self) unless self.skip_feed
  end

  def empty_perspective?
    return (memo.nil? or memo.length ==0) && (self.pictures.count == 0)
  end

  def parse_tags
    self.tags = extract_hashtags( self.memo.downcase ) unless self.memo.nil?
  end

  def fav_count
    self.starring_users.count
  end

  def flagme( user )
    if self.flag_count >= 0
      self.flag_count += 1
    end

    if self.flaggers.nil?
      self.flaggers = []
    end
    self.flaggers << user.id
  end

  def reset_user_and_place_perspective_count
    self.place.perspective_count = self.place.perspectives.count
    self.user.perspective_count = self.user.perspectives.count
    self.place.save!
    self.user.save!
  end
  
  def picture_details=(picture_details)
    picture_details.each do |picture|
      pictures.build(picture)
    end
  end
  
  def get_place_data
    self.place_location = self.place.location
    self.place_stub = PlaceStub.new
    place_attributes = self.place.attributes.except('address_components', 'cid', 'user_id')
    self.place_stub.attributes = place_attributes
  end

  def fix_location
    if self.location
      if self.location[0].is_a? String
        self.location[0] = self.location[0].to_f
      end
      if self.location[1].is_a? String
        self.location[1] = self.location[1].to_f
      end
    end
  end

  def favourite_perspectives
    favourites = []
    for perspective_id in self.favourite_perspective_ids
      favourites << Perspective.find( perspective_id )
    end

    return favourites
  end

  def as_json(options={})
    attributes = self.attributes.merge(:photos =>self.pictures.where(:deleted => false), :fav_count =>self.fav_count)
    attributes[:id] = attributes['_id']
    attributes.delete('place_stub')
    attributes.delete('uid')
    attributes[:place_id] = attributes.delete('plid')

    if options[:current_user]
      current_user = options[:current_user]

      if current_user.id ==  self[:uid]
        attributes = attributes.merge(:mine => true)
        attributes = attributes.merge(:starred => true)
      else
        attributes = attributes.merge(:mine => false)
        if self.starring_users.include?( current_user.id )
          attributes = attributes.merge(:starred => true)
        else
          attributes = attributes.merge(:starred => false)
        end
      end
    end

    if options[:detail_view] == true
      if current_user
        attributes.merge(:place => self.place.as_json({:current_user => current_user}),:user => self.user.as_json())
      else
        attributes.merge(:place => self.place_stub.as_json(),:user => self.user.as_json())
      end
    elsif options[:place_view]
      attributes.merge(:user => self.user.as_json())
    elsif options[:user_view]
      attributes.merge(:place => self.place.as_json())
    else
      attributes
    end

  end


  def self.extract_tag_array( query )
    tags = []
    for term in query.split
      if term[0,1] == '#'
        tags << term[1..-1]
      else
        tags << term
      end
    end

    return tags
  end


end
