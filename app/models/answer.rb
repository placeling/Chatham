class Answer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :comment, :type => String
  field :upvotes, :type => Integer
  field :downvotes, :type => Integer
  has_one :place

  embedded_in :question

end