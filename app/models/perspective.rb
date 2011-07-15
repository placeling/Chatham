class Perspective
  include Mongoid::Document
  include Mongoid::Timestamps

  field :boolean, :type => Boolean, :default => TRUE

  embedded_in :user
  belongs_to :person
end
