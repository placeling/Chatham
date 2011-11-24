class PotentialPlace
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
  field :gid, :type => String
  
  field :loc, :as => :location, :type => Array
  
  field :score, :type => Float
  
  field :reference, :type => String
end