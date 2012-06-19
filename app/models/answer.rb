class Answer
  include Mongoid::Document
  include Mongoid::Timestamps
  include ApplicationHelper

  field :upvotes, :type => Integer, :default => 0
  field :voters, :type =>Hash, :default => {}
  belongs_to :place

  embedded_in :question

  embeds_many :answer_comments

  validates_presence_of :place
  validate :acceptable_distance, :on => :create

  def acceptable_distance
    dist = haversine_distance( self.question.location[0], self.question.location[1], self.place.location[0], self.place.location[1] )

    if dist["km"] >50
      #too far away
      errors[:base] << I18n.t('question.too_far', :name => self.place.name)
    end
  end

end