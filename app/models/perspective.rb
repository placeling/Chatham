class Perspective
  include Mongoid::Document
  include Mongoid::Timestamps
  before_validation :fix_location
  before_save :get_place_location
  before_save :increment_place_and_user
  after_destroy :decrement_place_and_user

  validates_associated :place
  validates_associated :user

  field :favorite,    :type => Boolean, :default => TRUE
  field :memo,        :type => String
  field :place_location,    :type => Array #for easier indexing

  #these are meant for internal use, not immediately visible to user -iMack
  field :location,    :type => Array
  field :accuracy,      :type => Float

  belongs_to :place
  belongs_to :user
  belongs_to :client_application

  embeds_many :pictures

  index [[ :place_location, Mongo::GEO2D ]], :min => -180, :max => 180
  index [[ :location, Mongo::GEO2D ]], :min => -180, :max => 180

  def increment_place_and_user
    self.place.perspective_count += 1
    self.user.perspective_count += 1
    self.place.save!
    self.user.save!
  end

  def decrement_place_and_user
    self.place.perspective_count -= 1
    self.user.perspective_count -= 1
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
    if options[:top_level] == false
      attributes.merge(:place => place, :photos =>pictures)
    else
      attributes.merge(:place => place, :photos =>pictures, :user => user)
    end

  end
end
