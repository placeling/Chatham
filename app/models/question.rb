class Question
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :description, :type => String
  field :city_name, :type => String
  field :country_code, :type => String
  field :loc, :as => :location, :type => Array
  field :score, :type => Integer, :default => 0

  embeds_many :answers
  belongs_to :user

  index [[ :loc, Mongo::GEO2D ]], :min => -180, :max => 180

  before_validation :fix_location

  validates_presence_of :loc
  validates_presence_of :title
  validates_length_of :title, :minimum => 10, :maximum => 80
  validates_presence_of :city_name
  validates_presence_of :country_code

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
      if self.location[0] == 0.0 and self.location[1] == 0.0
        errors.add(:base, "You didn't include a latitude and longitude")
      end
  end



  def og_path
    "#{ApplicationHelper.get_hostname}#{ Rails.application.routes.url_helpers.question_path( self ) }"
  end

end
