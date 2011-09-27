class Activity
  include Mongoid::Document
  include Mongoid::Timestamps

  field :activity_type, :type => String

  field :user1, :as => :actor1, :type => BSON::ObjectId
  field :username1, :type => String

  field :user2, :as => :actor2, :type => BSON::ObjectId
  field :username2, :type => String

  field :subject, :type => BSON::ObjectId
  field :subject_title, :type => String

  embedded_in :activity_feed_chunk

  validates_presence_of :actor1, :username1

end