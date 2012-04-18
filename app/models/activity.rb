require 'redis_helper'

class Activity
  include Mongoid::Document
  include Mongoid::Timestamps
  include RedisHelper

  field :activity_type, :type => String

  field :user1, :as => :actor1, :type => BSON::ObjectId
  field :username1, :type => String
  field :thumb1, :type => String
  
  field :user2, :as => :actor2, :type => BSON::ObjectId
  field :username2, :type => String

  field :subject, :type => BSON::ObjectId
  field :subject_title, :type => String

  embedded_in :activity_feed_chunk

  validates_presence_of :actor1, :username1

  # push status to a specific feed
  def push(id, location="feed")
    $redis.zadd key(location, id), timestamp, encoded
  end

  # push to followers (assumes an array of follower ids)
  def push_to_followers( user )
    user.followers.each do |follower|
      push( follower.id )
    end
    #push onto the superfeed
    $redis.zadd "FIREHOSEFEED", timestamp, encoded
  end

  def self.decode(json)
    Activity.new(ActiveSupport::JSON.decode(json))
  end

  def as_json(options={})
    #these could eventually be paginated #person.posts.paginate(page: 2, per_page: 20)

    if self.thumb1.nil?
      user = User.find_by_username(self.username1)
      if user && user.thumb_url
        self.thumb1 = user.thumb_url
      end
    end

    self.attributes
  end

end