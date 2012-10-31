class Publisher
  include Mongoid::Document
  field :username, :type => String
  field :categories, :type => Hash, :default => {}
  field :css, :type => String, :default => ""
  field :footerpng, :type => String
  field :wellpng, :type => String
  field :liquid, :type => String


end
