require 'google_geocode'

class PotentialPerspective
  include ApplicationHelper
  include Mongoid::Document
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :notes, :type => String
  
  field :loc, :as => :location, :type => Array
  
  field :address, :type => String
  field :locality, :type => String
  field :state_prov, :type => String
  field :country, :type => String
  field :postal_code, :type => String
  
  field :status, :type => String
  
  field :url,       :type => String
  
  belongs_to :user
  belongs_to :place
  
  embeds_many :pictures
  
  before_save :set_status
  
  validates :url, :format => { :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,
      :message => "Invalid URL" }
  
  RADIUS = 250
  
  def username
    if !self.user.nil?
      self.user.username
    end
  end

  def username=(name)
    found_user = User.where(:username=>name)[0]
    self.user = found_user
  end
  
  def set_status
    # red - can't geocode address or invalid lat/lng
    # yellow - geocoded but no valid location object
    # green - place attached
    # black - place attached but user already has perspective for that location
    
    status_set = false
    
    if self.place.nil?
      # 0.0 is what ("a string").to_f resolves to
      if self.location.length < 2 or self.location[0].nil? or self.location[1].nil? or \
        self.location[0] == 0.0 or self.location[1] == 0.0 or self.location[0] > 90.0 \
        or self.location[0] < -90.0 or self.location[1] > 180.0 or self.location[1] < -180.0
          # If invalid lat/lng and no street address, don't even bother geocoding
          # Otherwise may end up with geocoded cities, etc.
          if self.address.nil?
            self.status = "red"
            status_set = true
          else
            geocoder = GoogleGeocode.new
            address_pieces = []
            if !self.address.nil?
              address_pieces.push(self.address)
            end
            if !self.locality.nil?
              address_pieces.push(self.locality)
            end
            if !self.state_prov.nil?
              address_pieces.push(self.state_prov)
            end
            if !self.postal_code.nil?
              address_pieces.push(self.postal_code)
            end
            if !self.country.nil?
              address_pieces.push(self.country)
            end
            result = geocoder.geocode(address_pieces)
            
            if result and (result.types.include? "street_address" or result.types.include? "subpremise" \
              or result.types.include? "premise" or result.types.include? "point_of_interest")
                self.location[0] = result.geometry.location.lat
                self.location[1] = result.geometry.location.lng
            else
              self.status = "red"
              status_set = true
            end
          end
      end
    end
    
    if !status_set
      if self.place.nil?
        placer = GooglePlaces.new
        results = placer.find_nearby(self.location[0], self.location[1], 100, self.name)
        # Can only be sure if exact match
        # If length == 1
        # And name is same
        # And within 250 m 
        if results.length == 1
          delta = haversine_distance(results[0].geometry.location.lat, results[0].geometry.location.lng, self.location[0], self.location[1])['m']
        end
        
        if results.length == 1 && results[0].name == self.name && delta < RADIUS
          place = Place.find_by_google_id( results[0].id )
        
          if place.nil?
            gp = GooglePlaces.new
            place = Place.new_from_google_place( gp.get_place( results[0].reference ) )
            place.user = self.user
            place.save!
          end
        
          self.place = place
          self.location = place.location
        end
      end
      
      if !self.place.nil?  
        # check if user already has perspective for that place
        perspectives = Perspective.where({:uid => self.user.id})
        perspectives.each do |perp|
          if perp.place == @place
            self.status = "black"
            status_set = true
          end
        end
        
        if status_set == false
          self.status = "green"
        end
      else
        self.status = "yellow"
        status_set = true
      end
    end
  end
end
