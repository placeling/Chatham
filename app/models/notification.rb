require 'redis_helper'

class Notification
  include Mongoid::Document #doesn't actually get persisted
  include Mongoid::Timestamps
  include RedisHelper

  field :actor1, :type => BSON::ObjectId
  field :actor2, :type => BSON::ObjectId
  field :subject, :type => BSON::ObjectId
  field :type, :type => String
  field :subject_name, :type => String
  field :email, :type => Boolean, :default => false
  field :apns, :type => Boolean, :default => false


  def self.veto(activity)
    user = User.find(activity.actor2)

    for notification in user.notifications
      if notification.type == activity.activity_type
        if notification.actor1 == activity.actor1
          if notification.subject == activity.subject
            if notification.actor2 == activity.actor2
              return true
            end
          end
        end
      end
    end

    return false
  end

  # push status to a specific feed
  def remember(location="notifications")
    self.created_at = Time.now
    $redis.zadd key(location, self.actor2), timestamp, encoded
  end

  def self.decode(json)
    Notification.new(ActiveSupport::JSON.decode(json))
  end

  def as_json(options={})
    self.attributes.merge(:id => self[:_id],)
  end


end