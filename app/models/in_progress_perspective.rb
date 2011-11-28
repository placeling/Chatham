require 'google_geocode'
require 'set'

GOOGLE_RADIUS = 50 # Use 50m as if larger, may not see user-created places
NEARBY_PRECISION = 150 # Only consider a place a match if within this radis of user-entered lat/lng
RAD_PER_DEG = 0.017453293  #  PI/180
EARTH_RADIUS_METERS = 6371000

class InProgressPerspective
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
  
  belongs_to :user, :index => true
  belongs_to :place
  
  has_and_belongs_to_many :potential_places, :inverse_of => nil
  
  before_save :set_status
  
  validates :url, :format => { :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,
      :message => "Invalid URL" }
  
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
      if self.place.nil? and (self.potential_places.nil? or self.potential_places.length == 0)
        placer = GooglePlaces.new
        results = placer.find_nearby(self.location[0], self.location[1], GOOGLE_RADIUS, self.name)
        sleep 1 # Pause for 1 second so don't ever overload Google Places API requests
        
        if results.length == 1
          # Do not naively assume place is a match. Google Places can return results that are completely off
          if results[0].name == self.name and nearby(self.location[0], self.location[1], results[0].geometry.location.lat, results[0].geometry.location.lng, NEARBY_PRECISION)
            
            place = Place.find_by_google_id( results[0].id )
            
            if place.nil?
              gp = GooglePlaces.new
              place = Place.new_from_google_place( gp.get_place( results[0].reference ) )
              place.user = self.user
              place.save!
            end
            
            self.place = place
            self.location = place.location 
            self.status = "green"           
          end
        end
        # If not exact match, get all nearby places and whittle down list
        if self.place.nil?
          results += placer.find_nearby(self.location[0], self.location[1], GOOGLE_RADIUS)
          sleep 1 # Pause for 1 second so don't ever overload Google Places API requests
          
          found_ids = []
          
          results.each do |candidate|
            match, score = find_match(self.name, candidate.name)
            
            if match
              if !found_ids.include?(candidate.id)
                found_ids << candidate.id
                
                # UPDATE HOW THIS IS CODED TO BE NICER
                
                potential_place = PotentialPlace.new
                potential_place.name = candidate.name
                potential_place.score = score
                potential_place.gid = candidate.id
                potential_place.reference = candidate.reference
                potential_place.location = [candidate.geometry.location.lat, candidate.geometry.location.lng]
                
                potential_place.save
                
                self.potential_places.push(potential_place)
              end
            end
          end
          self.status = "yellow"
        end
      else
        self.status = "green"
      end
      status_set = true
    end
  end
end


def nearby(lat1, lng1, lat2, lng2, delta)
  # Draw heavily from code at: http://www.esawdust.com/blog/gps/files/HaversineFormulaInRuby.html
  dlng = lng2 - lng1
  dlat = lat2 - lat1
  
  dlng_rad = dlng * RAD_PER_DEG
  dlat_rad = dlat * RAD_PER_DEG
  
  lat1_rad = lat1 * RAD_PER_DEG
  lng1_rad = lng1 * RAD_PER_DEG
  
  lat2_rad = lat2 * RAD_PER_DEG
  lng2_rad = lng2 * RAD_PER_DEG
  
  a = (Math.sin(dlat_rad/2))**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * (Math.sin(dlng_rad/2))**2
  c = 2 * Math.atan2( Math.sqrt(a), Math.sqrt(1-a))
  
  dMeters = EARTH_RADIUS_METERS * c # Distance between two points in meters
  
  if dMeters > delta
    return false
  else
    return true
  end
end

# Damerau-Levinshtein distance between two strings
# For background info: http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance
# Code from: https://gist.github.com/182759
def dameraulevenshtein(seq1, seq2)
    oneago = nil
    thisrow = (1..seq2.size).to_a + [0]
    seq1.size.times do |x|
        twoago, oneago, thisrow = oneago, thisrow, [0] * seq2.size + [x + 1]
        seq2.size.times do |y|
            delcost = oneago[y] + 1
            addcost = thisrow[y - 1] + 1
            subcost = oneago[y - 1] + ((seq1[x] != seq2[y]) ? 1 : 0)
            thisrow[y] = [delcost, addcost, subcost].min
            if (x > 0 and y > 0 and seq1[x] == seq2[y-1] and seq1[x-1] == seq2[y] and seq1[x] != seq2[y])
                thisrow[y] = [thisrow[y], twoago[y-2] + 1].min
            end
        end
    end
    return thisrow[seq2.size - 1]
end

def tokenized_dameraulevensthein(seq1, seq2)
  distance_per_token_count = {}
  
  seq1_tokens = seq1.split(" ")
  seq1_tokens.each do |token|
    distance_per_token_count[token] = 10000
  end
  
  seq1_tokens.each do |start_token|
    seq2_tokens = seq2.split(" ")
    seq2_tokens.each do |compare_token|
      distance = dameraulevenshtein(start_token, compare_token)
      if distance < distance_per_token_count[start_token]:
        distance_per_token_count[start_token] = distance
      end
    end
  end
  
  total_distance = 0
  distance_per_token_count.each_value { |value| total_distance += value }
  
  return total_distance
end

def token_overlap(seq1, seq2)
  tokens1 = seq1.split(" ")
  tokens2 = seq2.split(" ")
  
  set1 = Set.new []
  set2 = Set.new []
  
  tokens1.each do |token|
    set1.add(token)
  end
  
  tokens2.each do |token|
    set2.add(token)
  end
  
  max_length = 0
  set1.intersection(set2).each do |token|
    if token.length > max_length:
      max_length = token.length
    end
  end
  
  return set1.union(set2), set1.intersection(set2), max_length
end

def find_match(str1, str2)
  str1_clean = str1.sub("(","").sub(")","").sub("-","").sub(".","").downcase
  str2_clean = str2.sub("(","").sub(")","").sub("-","").sub(".","").downcase
  
  union, intersection, max_length = token_overlap(str1_clean, str2_clean)
  
  if intersection.count() == 0:
    return false, 0.0
  end
  
  # Score:
  # 1/2 = string coverage
  # 1/2 = per token levenshtein distance
  # 
  # Note from Lindsay: I did a few tests of different simple algorithms and this one seemed to give the best results
  
  string_coverage_score = (intersection.to_a.join().length() * 1.0) / union.to_a.join().length()
  levenshtein_score = 1 - (tokenized_dameraulevensthein(str1_clean, str2_clean) * 1.0) / str1_clean.length()
  
  final_score = 0.5 * string_coverage_score + 0.5 * levenshtein_score
  
  return true, final_score
end
