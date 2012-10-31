class Publisher
  include Mongoid::Document
  field :css, :type => String, :default => ""
  field :footerpng, :type => String
  field :wellpng, :type => String
  field :liquid, :type => String

  accepts_nested_attributes_for :publisher_categories, allow_destroy: true
  embeds_many :publisher_categories

  belongs_to :user

  validates_presence_of :user

  def category_for(category)
    return self.publisher_categories.where(:slug => category).first
  end
end
