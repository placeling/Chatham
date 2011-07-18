class Perspective
  include Mongoid::Document
  include Mongoid::Timestamps
  before_validation :fix_location
  before_save :get_place_location

  validates_presence_of :place
  validates_presence_of :user

  field :favorite,    :type => Boolean, :default => TRUE
  field :memo,        :type => String

  #these are meant for internal use, not immediately visible to user -iMack
  field :place_location,    :type => Array
  field :location,    :type => Array
  field :radius,      :type => Float

  belongs_to :place
  belongs_to :user

  index [[ :place_location, Mongo::GEO2D ]], :min => -180, :max => 180
  index [[ :location, Mongo::GEO2D ]], :min => -180, :max => 180

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
    attributes.merge(:place => place)
  end
end
