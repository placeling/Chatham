require 'feedzirra'

class Blogger
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps

  field :title, :type => String
  field :city_name, :type => String
  field :url, :type => String
  field :feed_url, :type => String
  field :hostname, :type => String

  field :twitter, :type => String
  field :email, :type => String

  field :wordpress, :type => Boolean, :default => false
  field :activated, :type => Boolean, :default => false
  field :auto_crawl, :type => Boolean, :default => true
  
  field :featured, :type => Boolean, :default => false # Editorial flag
  
  field :places_count, :type => Integer, :default => 0

  field :last_updated, :type => DateTime, :default => 2.days.ago

  field :location, :type => Array
  slug :title, :index => true, :permanent => true

  embeds_many :entries
  belongs_to :place
  field :pid, :type => String
  
  index :url
  index :hostname
  index :place

  index [["entries.location", Mongo::GEO2D]], :min => -180, :max => 180

  def self.find_by_url(url)
    Blogger.where(:url => url).first
  end

  def place_count
    tally = 0
    self.entries.each do |entry|
      if entry.places.count > 0
        tally +=1
      end
    end
    return tally
  end

  def update_from_feedrizza(feed)
    self.title = feed.title
    if defined?(feed.generator) && !feed.generator.nil?
      self.wordpress = feed.generator.include? "wordpress"
    else
      self.wordpress = false
    end
  end

  def last_entry_date
    if self.entries.length == 0
      return false
    else
      last_update = self.entries[0].published
      self.entries.each do |entry|
        if entry.published and entry.published > last_update
          last_update = entry.published
        end
      end
      return last_update
    end
  end

  def update_rss_feed
    feed = Feedzirra::Feed.fetch_and_parse(self.feed_url, {:max_redirects => 3, :timeout => 10})

    if feed.nil? || !defined?(feed.entries) || feed.entries.nil? || feed.entries.first.nil? || (feed.entries.first.published && feed.entries.first.published < 3.months.ago)
      self.last_updated = 1.second.ago
      self.save
      return
    end

    feed.entries.each do |entry|
      exists = Blogger.where("entries.guid" => entry.id).first()

      if !exists and !entry.published.nil?
        if entry.content.nil?
          self.entries.create(:guid => entry.id, :url => entry.url, :title => entry.title, :content => entry.summary, :slug => entry.entry_id, :published => entry.published)
        else
          self.entries.create(:guid => entry.id, :url => entry.url, :title => entry.title, :content => entry.content, :slug => entry.entry_id, :published => entry.published)
        end
      end
    end

    self.last_updated = 1.second.ago
    self.save
  end

  def empty_feed
    self.entries = []
    self.last_updated = 2.days.ago
    self.save
  end

  def as_json(options={})
    self.attributes.delete('entries')
    self.attributes
  end
  
  def self.group_by_place
    place_counts = Blogger.collection.group(
      :cond => {:auto_crawl => false},
      :key => 'pid',
      :initial => {count: 0},
      :reduce => "function(obj,prev) {prev.count++}"
    )
    
    return place_counts
  end
end