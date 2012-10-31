class Publisher
  include Mongoid::Document
  field :css, :type => String, :default => ""
  field :footerpng, :type => String
  field :wellpng, :type => String
  field :liquid, :type => String

  accepts_nested_attributes_for :publisher_categories, allow_destroy: true
  embeds_many :publisher_categories

  belongs_to :user


end
