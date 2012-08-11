class PlacemarkComment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :comment, :type => String
  field :upvotes, :type => Integer, :default => 1

  field :username, :type => String

  belongs_to :user
  embedded_in :perspective

  validates_presence_of :user
  validates_length_of :comment, :minimum => 1

end