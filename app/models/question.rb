class Question
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  field :title, :type => String
  field :description, :type => String
  field :city_name, :type => String
  field :country_code, :type => String
  field :loc, :as => :location, :type => Array
  field :score, :type => Integer, :default => 0

  slug :title, :index => true, :permanent => true

  embeds_many :answers
  belongs_to :user

  index [[:loc, Mongo::GEO2D]], :min => -180, :max => 180

  before_validation :fix_location

  validates_presence_of :loc
  validates_length_of :title, :minimum => 6, :maximum => 80
  validates_presence_of :city_name
  validates_presence_of :country_code

  before_create :fixup_title

  def fixup_title
    self[:title] = "#{self[:title]} in #{self[:city_name]}?"
  end

  def self.nearby_questions(lat, long)
    Question.where(:loc.within => {"$center" => [[lat, long], 0.1]}).
        and(:score.gte => 1)
  end

  def self.nearby_random_questions(lat, long)
    Question.where(:loc.within => {"$center" => [[lat, long], 0.1]}).
        and(:score.gte => 1).
        order(:random)
    limit(5)
  end

  def self.suggest_for(user)
    Question.first
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

end
