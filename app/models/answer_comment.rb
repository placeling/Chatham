class AnswerComment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :comment, :type => String
  field :upvotes, :type => Integer, :default => 0

  field :username, :type => String

  belongs_to :user
  embedded_in :answer

end