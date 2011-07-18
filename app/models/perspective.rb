class Perspective
  include Mongoid::Document
  include Mongoid::Timestamps
  before_validation :fix_location

  field :favorite,    :type => Boolean, :default => TRUE
  field :memo,        :type => String

  #these are meant for internal use, not immediately visible to user -iMack
  field :location,    :type => Array
  field :radius,      :type => Float

  belongs_to :place
  belongs_to :user

  index [[ :location, Mongo::GEO2D ]], :min => -180, :max => 180

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
