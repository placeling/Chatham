class Suggestion
  include Mongoid::Document
  include Mongoid::Timestamps

  field :message, :type => String

  belongs_to :sender, :class_name => "User"
  belongs_to :receiver, :class_name => "User"
  belongs_to :place

  validates_presence_of :message
  validates_presence_of :sender
  validates_presence_of :receiver
  validates_presence_of :place


  def self.find_suggested_for_user(user, start=0, count = 20)
    Suggestion.where(:receiver_id => user.id).
        skip(start).
        limit(count)
  end

end
