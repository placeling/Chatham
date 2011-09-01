class Perspective
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Twitter::Extractor


  before_validation :fix_location
  before_save :get_place_location
  before_save :parse_tags
  after_save :reset_user_and_place_perspective_count
  after_destroy :reset_user_and_place_perspective_count

  validates_associated :place
  validates_associated :user

  field :memo,        :type => String
  field :place_location,    :type => Array #for easier indexing
  field :tags,    :type => Array
  field :fav_count, :type => Integer, :default =>0

  #these are meant for internal use, not immediately visible to user -iMack
  field :location,    :type => Array
  field :accuracy,      :type => Float

  belongs_to :place
  belongs_to :user
  belongs_to :client_application

  embeds_many :pictures

  index [[ :place_location, Mongo::GEO2D ]], :min => -180, :max => 180
  index [[ :location, Mongo::GEO2D ]], :min => -180, :max => 180
  index :tags, :background => true

  def parse_tags
    self.tags = extract_hashtags( self.memo )
  end

  def reset_user_and_place_perspective_count
    self.place.perspective_count = self.place.perspectives.count
    self.user.perspective_count = self.user.perspectives.count
    self.place.save!
    self.user.save!
  end

  def get_place_location
    self.place_location = self.place.location
  end

  def fix_location
    if self.location[0].is_a? String
      self.location[0] = self.location[0].to_f
    end
    if self.location[1].is_a? String
      self.location[1] = self.location[1].to_f
    end
  end

  def as_json(options={})
    attributes = self.attributes.merge(:photos =>pictures)

    if options[:current_user]
      user = options[:current_user]
      if user.favourite_perspectives.include?( self.id )
        attributes = attributes.merge(:starred => true)
      else
        attributes = attributes.merge(:starred => false)
      end
    end

    if options[:detail_view] == true
      attributes.merge(:place => place.as_json(),:user => user.as_json())
    elsif !options[:raw_view]
      attributes.merge(:place => place.as_json())
    else
      attributes
    end

  end
end
