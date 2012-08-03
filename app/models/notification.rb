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
  field :thumb1, :type => String


  def self.veto(activity)
    user = User.find(activity.actor2)
    notifications = user.notifications

    if notifications.count >=5
      notty = notifications[4]
      if notty.created_at > 1.hour.ago
        return true
      end
    end

    for notification in notifications
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

    user = User.find(self.actor1)

    self.attributes.merge(:id => self[:_id], :thumb1 => user.thumb_url)
  end


end