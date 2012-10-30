class Question
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  field :title, :type => String
  field :description, :type => String
  field :city_name, :type => String
  field :country_code, :type => String
  field :loc, :as => :location, :type => Array
  field :score, :type => Integer, :default => 1
  field :subs, :as => :subscribers, :type => Array, :default => []

  slug :title, :index => true, :permanent => true

  embeds_many :answers
  belongs_to :user

  index [[:loc, Mongo::GEO2D]], :min => -180, :max => 180

  before_validation :fix_location

  validates_presence_of :loc
  validates_length_of :title, :minimum => 6, :maximum => 80
  validates_presence_of :city_name
  validates_presence_of :country_code

  def self.nearby_questions(lat, long)
    Question.where(:loc.within => {"$center" => [[lat, long], 0.2]}).
        and(:score.gte => 1)
  end

  def self.nearby(lat, lng)
    Question.where(:loc => {"$near" => [lat, lng]}).
        limit(10)
  end

  def self.nearby_random_questions(lat, long)
    Question.where(:loc.within => {"$center" => [[lat, long], 0.2]}).
        and(:score.gte => 1).
        order(:random)
    limit(5)
  end

  def self.suggest_for(user)
    Question.first
  end

  def comment_count
    tally = 0
    answers.each do |answer|
      tally += answer.answer_comments.count
    end
    return tally
  end

  def fix_location
    begin
      if self.location[0].is_a? String
        self.location[0] = self.location[0].to_f
      end
      if self.location[1].is_a? String
        self.location[1] = self.location[1].to_f
      end
    rescue
      errors.add(:base, "You didn't include a latitude and longitude")
    end
    if self.location.nil? || (self.location[0] == 0.0 and self.location[1] == 0.0)
      errors.add(:base, "You didn't include a latitude and longitude")
    end
  end


  def og_path
    "#{ApplicationHelper.get_hostname}#{ Rails.application.routes.url_helpers.question_path(self) }"
  end

  def as_json(options={})
    attributes = {
        :id => self['_id'],
        :title => self['title'],
        :lat => self.location[0],
        :lng => self.location[1],
        :description => self.description,
        :city_name => self.city_name,
        :location => self.location,
        :score => self.score,
        :country_code => self.country_code,
        :created_at => self.created_at
    }

    attributes = attributes.merge(:user => self.user)
    attributes = attributes.merge(:answers => self.answers)
  end

end
