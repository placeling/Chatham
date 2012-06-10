class Answer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :comment, :type => String
  field :upvotes, :type => Integer, :default => 0
  belongs_to :place

  embedded_in :question

end