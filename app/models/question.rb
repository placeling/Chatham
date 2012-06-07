class Question
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :description, :type => String
  field :city_name, :type => String
  field :loc, :as => :location, :type => Array

  embeds_many :answers
  belongs_to :user

  index [[ :loc, Mongo::GEO2D ]], :min => -180, :max => 180

end
