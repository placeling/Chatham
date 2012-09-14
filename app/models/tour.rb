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
  
  def self.forgiving_find(tour_id)
    if BSON::ObjectId.legal?(tour_id)
      tour = Tour.find(tour_id)
    else
      tour = Tour.find_by_slug tour_id
    end
    return tour
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