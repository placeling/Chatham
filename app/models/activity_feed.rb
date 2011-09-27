
class ActivityFeed
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :user

  has_many :activity_feed_chunks, :foreign_key => "aid"

  def self.add_follow(actor1, actor2)
    activity = actor1.build_activity

    activity.activity_type = "FOLLOW"

    activity.actor2 = actor2.id
    activity.username2 = actor2.username
    activity.save
  end

  def self.add_new_perspective(actor1, perspective)
    activity = actor1.build_activity

    activity.activity_type = "NEW_PERSPECTIVE"

    activity.subject = perspective.id
    activity.subject_title = perspective.place.name

    activity.save
  end

  def self.add_update_perspective(actor1, perspective)
    activity = actor1.build_activity

    activity.activity_type = "UPDATE_PERSPECTIVE"

    activity.subject = perspective.id
    activity.subject_title = perspective.place.name

    activity.save
  end

  def self.add_star_perspective(actor1, actor2, perspective)
    activity = actor1.build_activity

    activity.activity_type = "STAR_PERSPECTIVE"

    activity.actor2 = actor2.id
    activity.username2 = actor2.username

    activity.subject = perspective.id
    activity.subject_title = perspective.place.name
    activity.save
  end

  def head_chunk
    head = self.activity_feed_chunks.where(:current => true).first
    if head == nil
      chunk = self.activity_feed_chunks.build(:current =>true, :first_update => Time.now)
      chunk.activity_feed = self
      chunk.save
    elsif head.is_full?
      head.current = false
      head.next = chunk
      chunk = self.activity_feed_chunks.build(:current =>true, :first_update => Time.now)
    else
      chunk = head
    end

    return chunk
  end

  def activities(start = 0, n=20)
    chunk = head_chunk
    first_chunk = chunk

    activities = []

    i = 0
    j = 0

    #put the cursor to the correct starting position
    while i < start
      if chunk == nil
        return activities
      end
      if i + chunk.activities.count < start
        chunk = chunk.next
        i = i + chunk.activities.count
      else
        j =  start - i
      end
    end
    i = i + j

    chunk = first_chunk
    while i < start + n
      if chunk.nil?
        return activities
      end
      if i +chunk.activities.count < start + n
        #need the order by because of Mongoid bug 1255
        activities = activities + chunk.activities.order_by([[:created_at, :desc]])[j..chunk.activities.count]
        j=0
        i = i + chunk.activities.count - j
        chunk = chunk.next
      else
        activities = activities + chunk.activities.order_by([[:created_at, :desc]])[j..(start+n -i)]
        i = i + (chunk.activities.count -j)
      end
    end

    return activities

  end

end

