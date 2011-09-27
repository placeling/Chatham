MAX_EMBED = 100


class ActivityFeedChunk
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia

  field :current, :type => Boolean

  belongs_to :activity_feed, :foreign_key => 'aid' #, :index =>true

  belongs_to :next, :foreign_key => 'afcid'
  has_one :activity_feed_chunk, :as => :previous, :foreign_key => 'afcid'

  field :first_update, :type => DateTime

  embeds_many :activities

  def is_full?
    return self.activities.count >= MAX_EMBED
  end
end