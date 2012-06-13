class Answer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :upvotes, :type => Integer, :default => 0
  field :voters, :type =>Hash, :default => {}
  belongs_to :place

  embedded_in :question

  embeds_many :answer_comments

  validates_presence_of :place

end