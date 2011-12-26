
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

  field :venue_types, :type => Array
  field :google_url,  :type => String
  field :place_type,  :type => String
  field :pc, :type => Integer, :default => 0 #property for easier lookup of of top places

  field :google_ref,  :type => String # may need this later, makes easier
  field :ptg, :type => Array
  field :place_tags_last_update, :type => DateTime
  
  embedded_in :perspective


end