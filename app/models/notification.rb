require 'redis_helper'

class Notification
  include Mongoid::Document #doesn't actually get persisted
  include Mongoid::Timestamps
  include RedisHelper

  field :user, :as => :actor1, :type => BSON::ObjectId
  field :subject, :type => BSON::ObjectId
  field :type, :type => String
  field :subject_name, :type => String
  field :email, :type => Boolean, :default => false
  field :apns, :type => Boolean, :default => false


  def self.veto(user, actor, notification_type)

    for notification in user.notifications
      if notification.type == notification_type && notification.subject == actor.id
        return true
      end
    end

    return false
  end

  # push status to a specific feed
  def remember(location="notifications")
    self.created_at = Time.now
    $redis.zadd key(location, self.actor1), timestamp, encoded
  end


  def self.decode(json)
    Notification.new(ActiveSupport::JSON.decode(json))
  end

  def as_json(options={})
    self.attributes.merge(:id => self[:_id],)
  end


end