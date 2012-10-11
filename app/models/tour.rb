class Tour
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Mongoid::Slug
  
  field :name, :type => String
  field :description, :type => String
  field :published, :type => Boolean, :default => false # 3 step create process; store unpublished until final step
  field :rendered, :type => Boolean, :default => false # rendering produces .png of tour
  
  slug :name, :index => true, :permanent => true
  
  belongs_to :user, :foreign_key => 'uid', :index => true
  field :position, :type => Array # has_and_belongs_to_many doesn't keep order of perspectives
  field :perspectives, :type => Array # pass perspective objects via this attribute; called every time need to create tour; not persisted
  
  # Geo info
  field :center, :type => Array # Needed to create Google Static map
  field :zoom, :type => Integer # Needed to create Google Static map
  field :ne, :as => :northeast, :type => Array # Needed for querying
  field :sw, :as => :southwest, :type => Array # Needed for querying
  
  mount_uploader :infographic, TourUploader, mount_on: :infographic_filename
  
  validates_presence_of :name, :center, :zoom, :northeast, :southwest
  validates_inclusion_of :zoom, :in => 0..21, :message => "Zoom must be between 0 and 21" 
  validates :name, :length => { :maximum => 30, :too_long => "Tour names can be up to %{count} characters long" }
  
  index [[:center, Mongo::GEO2D]], :min => -180, :max => 180
  index [[:ne, Mongo::GEO2D]], :min => -180, :max => 180
  index [[:sw, Mongo::GEO2D]], :min => -180, :max => 180
  
  def self.forgiving_find(tour_id)
    if BSON::ObjectId.legal?(tour_id)
      tour = Tour.find(tour_id)
    else
      tour = Tour.find_by_slug tour_id
    end
    return tour
  end
  
  def og_path
    "https://#{ActionMailer::Base.default_url_options[:host]}#{Rails.application.routes.url_helpers.user_tour_path(self.user, self)}"
  end
  
  def self.top_nearby(lat, lng, span=0.3, top_n=10)
    clean_tours = []
    raw_tours = Tour.where(:center.within => {"$center" => [[lat, lng], span]}).where(:rendered => true).entries
    
    # Make sure each is editorial quality
    raw_tours.each do |tour|
      if tour.recommendable?
        clean_tours << tour
      end
    end
    
    return clean_tours
  end
  
  def recommendable?
    # Requirements in order to recommend:
    # 1. Rendered
    # 2. At least 5 places
    # 3. At least one perspective contains an image
    if self.rendered == false
      return false
    end
    
    if self.position.length < 5
      return false
    end
    
    perps = self.active_perspectives
    perps.each do |perp|
      if perp.active_photos.length > 0
        return true
      end
    end
    
    return false
  end
  
  def random_photo
    photos = []
    perps = self.active_perspectives
    perps.each do |perp|
      perp.active_photos.each do |photo|
        photos << photo
      end
    end
    
    photos.shuffle!
    
    return photos
  end
  
  # Need to create custom ordering of @tour.perspectives because order lost between Mongo & Rails
  def active_perspectives
    self.perspectives = []
    
    active_perspectives = []
    
    if self.position
      self.position.each do |pid|
        persp = Perspective.find(pid)
        if !persp.nil?
          active_perspectives << persp
        end
      end
    end
    
    return active_perspectives
  end
end