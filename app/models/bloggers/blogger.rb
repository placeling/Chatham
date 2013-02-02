class Blogger
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  field :title, :type => String
  field :city_name, :type => String
  field :url, :type => String
  field :hostname, :type => String

  field :wordpress, :type => Boolean, :default => false
  field :activated, :type => Boolean, :default => false

  field :places_count, :type => Integer, :default => 0

  field :last_updated, :type => DateTime, :default => 2.days.ago

  field :location, :type => Array
  slug :title, :index => true, :permanent => true

  embeds_many :entries

  index :url
  index :hostname

  def self.find_by_url(url)
    Blogger.where(:url => url).first
  end

  def update_from_feedrizza(feed)
    self.title = feed.title
    if feed.generator
      self.wordpress = feed.generator.include? "wordpress"
    else
      self.wordpress = false
    end
  end

end