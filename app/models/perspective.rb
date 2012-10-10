require 'google_places'

class Perspective
  MAX_LENGTH = 130
  include Mongoid::Document
  include Mongoid::Timestamps
  include Twitter::Extractor

  field :memo, :type => String, :default => ""
  field :tags, :type => Array, :default => []
  field :url, :type => String
  field :flag_count, :type => Integer, :default => 0
  field :modified_at, :type => DateTime

  #these are meant for internal use, not immediately visible to user -iMack
  field :loc, :as => :location, :type => Array
  field :ploc, :as => :place_location, :type => Array
  field :flaggers, :type => Array
  field :accuracy, :type => Float
  field :empty, :type => Boolean, :default => true

  #contains starred perspectives this user has of on the place
  field :fp, :as => :favourite_perspective_ids, :type => Array, :default => []
  field :su, :as => :starring_users, :type => Array, :default => []

  belongs_to :place, :foreign_key => 'plid', :index => true
  belongs_to :user, :foreign_key => 'uid', :index => true
  belongs_to :client_application

  embeds_many :pictures
  embeds_many :placemark_comments, :cascade_callbacks => true
  accepts_nested_attributes_for :placemark_comments
  embeds_one :place_stub

  accepts_nested_attributes_for :pictures, :allow_destroy => true, :reject_if => lambda { |a| a[:content].blank? }

  index [["place_stub.loc", Mongo::GEO2D]], :min => -180, :max => 180
  index [[:ploc, Mongo::GEO2D]], :min => -180, :max => 180
  index [[:loc, Mongo::GEO2D]], :min => -180, :max => 180
  index "place_stub.venue_types"
  index "place_stub.ptg"
  index :tags, :background => true

  validates_associated :place
  validates_associated :user

  validates_format_of :url, :with => URI::regexp, :message => "Invalid URL", :allow_nil => true
  validates_uniqueness_of :uid, :scope => :plid, :on => :create

  before_validation :fix_location
  before_create :notify_modified
  before_save :set_empty_status
  before_save :get_place_data
  before_save :parse_tags
  after_save :reset_user_and_place_perspective_count
  after_destroy :reset_user_and_place_perspective_count
  after_create :check_in
  before_destroy :scrub_stars

  attr_accessor :post_delay, :distance, :liking_users

  def self.find_recent_for_user(user, start, count)
    user.perspectives.
        order_by([:modified_at, :desc]).
        skip(start).
        limit(count)
  end

  def self.find_nearby_for_user(user, loc, span, start, count)
    geonear = BSON::OrderedHash.new()
    geonear["$near"] = loc
    geonear["$maxDistance"] = span

    Perspective.where(:ploc => geonear).
        and(:uid => user.id).
        skip(start).
        limit(count)
  end

  def self.query_near_for_user(user, loc, span, query)
    selector = Perspective.where(:ploc => {"$near" => loc}).
        and(:uid => user.id)

    if query != nil and query.strip != ""
      tags = Perspective.extract_tag_array(query.downcase.strip)
      selector = selector.any_in(:tags => tags)
    end

    return selector
  end

  def short_memo
    if self.memo
      if self.memo.length < MAX_LENGTH
        return self.memo
      else
        return self.memo[0..MAX_LENGTH-1] + "..."
      end
    else
      return nil
    end
  end
  
  def high_value?
    if self.memo && self.memo.length > 10 && self.active_photos.length > 0
      return true
    else
      return false
    end
  end
  
  def self.query_near(loc, span, query, category)
    geonear = BSON::OrderedHash.new()
    geonear["$near"] = loc
    geonear["$maxDistance"] = span

    selector = Perspective.where(:ploc => geonear)

    if category != nil and category.strip != ""
      categories_array = CATEGORIES[category].keys + CATEGORIES[category].values
      selector = selector.any_in("place_stub.venue_types" => categories_array)
    end

    if query != nil and query.strip != ""
      tags = Perspective.extract_tag_array(query.downcase.strip)
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
    track! :placemark
  end

  def scrub_stars
    for perspective_id in self.favourite_perspective_ids
      perspective = Perspective.find(perspective_id)
      perspective.starring_users.delete(self['uid'])
    end

    for other_user_id in self.starring_users
      other_user = User.find(other_user_id)
      p2 = other_user.perspective_for_place(self.place)
      p2.favourite_perspective_ids.delete(self.id)
      p2.save
    end
  end

  def html_memo
    if self.memo && self.memo.length > 0
      text = self.memo
      text.gsub!(/\r\n?/, "</p><p>")
      text.gsub!(/\n+/, "</p><p>")
      return "<p>" + text + "</p>"
    else
      return nil
    end
  end

  def notify_modified
    self.modified_at = Time.now
  end

  def empty_perspective?
    if (memo.length > 0)
      return false
    elsif (memo.nil? or memo.length ==0) && (self.pictures.count == 0)
      return true
    else
      # Deleted photos aren't removed from model so need to calcuate
      self.pictures.each do |pic|
        if pic.deleted == false
          return false
        end
      end

      return true
    end
  end

  def set_empty_status
    if self.empty_perspective?
      self.empty = true
    else
      self.empty = false
    end
    # Must return true or execution will halt if set self.empty to false ("false" will be returned)
    return true
  end

  def active_photos
    photos = []
    self.pictures.each do |pic|
      if pic.deleted == false
        photos << pic
      end
    end

    return photos
  end

  def real_memo
    if self.memo && /\w/.match(self.memo)
      return true
    else
      return false
    end
  end

  def parse_tags
    self.tags = extract_hashtags(self.memo.downcase) unless self.memo.nil?
  end

  def fav_count
    self.starring_users.count
  end

  def flagme(user)
    if self.flag_count >= 0
      self.flag_count += 1
    end

    if self.flaggers.nil?
      self.flaggers = []
    end
    self.flaggers << user.id
  end

  def reset_user_and_place_perspective_count
    unless self.place.nil?
      self.place.perspective_count = self.place.perspectives.count
      self.place.save!
    end

    unless self.user.nil?
      self.user.perspective_count = self.user.perspectives.count #deleted user case
      self.user.save!
    end

  end

  def picture_details=(picture_details)
    picture_details.each do |picture|
      pictures.build(picture)
    end
  end

  def get_place_data
    self.place_location = self.place.location
    self.place_stub = PlaceStub.new
    place_attributes = self.place.attributes.except('address_components', 'cid', 'user_id', 'slug', 'html_attributions', "update_flag")
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
      favourites << Perspective.find(perspective_id)
    end

    return favourites
  end

  def og_path
    "#{ApplicationHelper.get_hostname}#{ Rails.application.routes.url_helpers.perspective_path(self) }"
  end

  def og_picture

    self.pictures.each do |picture|
      if !picture.deleted
        return picture.thumb_url
      end
    end

    return "#{ApplicationHelper.get_hostname}#{ActionController::Base.helpers.asset_path("Moustache.png")}"
  end

  def twitter_text(padding = 35)
    size = 140 - padding - self.place.name.length
    return self.memo[0..size] + "..."
  end

  def as_json(options={})

    #special check-empty perspective that is liking, return those values
    if false # self.empty_perspective? && self.favourite_perspectives.count >0
      perspective = self.favourite_perspectives[0]
      perspective.starring_users.delete(self.user.id)
      perspective.starring_users.insert(0, self.user.id) #move to front so will always show
      attributes = perspective.as_json(options)
      attributes['mine'] = false #prevent a highlight option
      return attributes
    end

    if self.liking_users.nil?
      for user_id in self.starring_users
        user = User.find(user_id)
        if self.liking_users
          self.liking_users << user.username
        else
          self.liking_users = [user.username]
        end
      end
    end

    attributes = {
        :id => self['_id'],
        :place_id => self['plid'],
        :tags => self.tags,
        :memo => self.memo,
        :url => self.url,
        :modified_at => self['modified_at'],
        :liking_users => self.liking_users,
        :comment_count => self.placemark_comments.count
    }
    if options[:bounds]
      attributes = attributes.merge(:photos => self.pictures.where(:deleted => false).as_json({:bounds => true}))
    else
      attributes = attributes.merge(:photos => self.pictures.where(:deleted => false).as_json())
    end

    if !self.modified_at
      attributes[:modified_at] = self.updated_at.getutc
    end

    if options[:bounds]
      attributes = attributes.merge(:ploc => self[:ploc])
      attributes = attributes.merge(:modified_timestamp => self[:modified_at])
      attributes[:memo] = self.html_memo
    end

    if options[:current_user]
      current_user = options[:current_user]

      if current_user.id == self[:uid]
        attributes = attributes.merge(:mine => true)
        attributes = attributes.merge(:starred => true)
      else
        attributes = attributes.merge(:mine => false)
        if self.starring_users.include?(current_user.id)
          attributes = attributes.merge(:starred => true)
        else
          attributes = attributes.merge(:starred => false)
        end
      end
    else
      attributes = attributes.merge(:mine => false)
    end

    if options[:detail_view] == true
      if current_user
        attributes.merge(:place => self.place.as_json({:current_user => current_user}), :user => self.user.as_json({:current_user => current_user}))
      else
        attributes.merge(:place => self.place.as_json(), :user => self.user.as_json())
      end
    elsif options[:place_view]
      attributes.merge(:user => self.user.as_json({:current_user => current_user}))
    elsif options[:user_view]
      if current_user
        if options[:bounds]
          attributes.merge(:place => self.place.as_json({:current_user => current_user, :bounds => true}))
        else
          attributes.merge(:place => self.place.as_json({:current_user => current_user}))
        end
      else
        if options[:bounds]
          attributes.merge(:place => self.place.as_json({:bounds => true}))
        else
          attributes.merge(:place => self.place.as_json())
        end
      end
      #else
      #  attributes
    end
  end


  def self.extract_tag_array(query)
    tags = []
    for term in query.split
      if term[0, 1] == '#'
        tags << term[1..-1]
      else
        tags << term
      end
    end

    return tags
  end


end
