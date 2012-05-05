
#this file is meant to be a stub that mirrors place information to keep in place for easy lookup

class PlaceStub
  include Mongoid::Document
  include Mongoid::Timestamps

  field :loc, :type => Array
  field :name, :type => String
  field :gid, :type => String
  field :vicinity, :type => String
  field :street_address, :type => String
  field :phone_number, :type => String
  field :city_data, :type => String
  field :accurate_address, :type => Boolean, :default => false

  field :venue_types, :type => Array
  field :venue_url,  :type => String
  field :google_url,  :type => String
  field :place_type,  :type => String
  field :pc, :type => Integer, :default => 0 #property for easier lookup of of top places

  field :google_ref,  :type => String # may need this later, makes easier
  field :ptg, :type => Array
  field :place_tags_last_update, :type => DateTime
  
  embedded_in :perspective


  def to_place
    place = Place.new

    place.attributes = self.attributes.except("gid", "loc", "ptg", "pc")
    place.google_id = self["gid"]
    place.location = self["loc"]
    place.place_tags = self["ptg"]
    place.perspective_count = self["pc"]

    return place
  end
end