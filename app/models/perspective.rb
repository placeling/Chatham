require 'google_places'

class Perspective
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Twitter::Extractor

  field :memo,        :type => String
  field :ploc, :as =>:place_location,    :type => Array #for easier indexing
  field :tags,    :type => Array
  field :fav_count, :type => Integer, :default =>0

  #these are meant for internal use, not immediately visible to user -iMack
  field :loc, :as => :location,    :type => Array
  field :accuracy,      :type => Float

  belongs_to :place, :foreign_key => 'plid' #, :index =>true
  belongs_to :user, :foreign_key => 'uid' #, :index =>true
  belongs_to :client_application

  embeds_many :pictures
  accepts_nested_attributes_for :pictures, :allow_destroy => true

  index [[ :ploc, Mongo::GEO2D ]], :min => -180, :max => 180
  index [[ :loc, Mongo::GEO2D ]], :min => -180, :max => 180
  index :tags, :background => true

  validates_associated :place
  validates_associated :user

  before_validation :fix_location
  before_save :get_place_location
  before_save :parse_tags
  after_save :reset_user_and_place_perspective_count
  after_destroy :reset_user_and_place_perspective_count
  after_create :check_in
  
  def check_in
    if self.place.google_id:
      gp = GooglePlaces.new
      output = gp.check_in(self.place.google_id)
    end
  end

  def empty_perspective?
    return (memo.nil? or memo.length ==0) && (self.pictures.count == 0)
  end

  def parse_tags
    self.tags = extract_hashtags( self.memo )
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
  
  def get_place_location
    self.place_location = self.place.location
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

  def as_json(options={})
    attributes = self.attributes.merge(:photos =>pictures)

    if options[:current_user]
      current_user = options[:current_user]

      if current_user.id ==  self[:uid]
        attributes = attributes.merge(:mine => true)
        attributes = attributes.merge(:starred => true)
      else
        attributes = attributes.merge(:mine => false)
        if current_user.favourite_perspectives.include?( self.id )
          attributes = attributes.merge(:starred => true)
        else
          attributes = attributes.merge(:starred => false)
        end
      end
    end

    if options[:detail_view] == true
      attributes.merge(:place => self.place.as_json(),:user => self.user.as_json())
    elsif options[:place_view]
      attributes.merge(:user => self.user.as_json())
    elsif options[:user_view]
      attributes.merge(:place => self.place.as_json())
    else
      attributes
    end

  end
end
