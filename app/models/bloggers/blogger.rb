class Blogger
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  field :title, :type => String
  field :city_name, :type => String
  field :base_url, :type => String
  field :hostname, :type => String

  field :wordpress, :type => Boolean, :default => false
  field :activated, :type => Boolean, :default => false

  field :places_count, :type => Integer, :default => 0

  field :location, :type => Array
  slug :title, :index => true, :permanent => true

  #embeds_many :entries

  index :base_url
  index :hostname

  def self.find_by_url(url)
    Blogger.where(:base_url => url).first
  end

end