require 'json'

class GooglePlacesAutocomplete
  include HTTParty
  debug_output $stdout
  
  # api docs: http://code.google.com/apis/maps/documentation/places/autocomplete.html
  base_uri "https://maps.googleapis.com/maps/api/place/autocomplete"
  
  def initialize()
    @api_key = CHATHAM_CONFIG['google_api']
  end

  def suggest(x, y, radius, input, sensor = true, type_array = "establishment", language ="en")
    #radius is in meters
    
    location = [x,y].join(',')
    
    options = {
      :location => location,
      :sensor => sensor,
      :types => type_array,
      :input => input,
      :radius => radius
    }
    
    results = mashup( self.class.get("/json", :query => options.merge(self.default_options)) ).predictions
    
    return results
  end
  
  #for testing
  def api_key
    return @api_key
  end
  
  def api_key=(value)
    @api_key = value
  end
  
  protected
    def default_options
      { :key => @api_key }
    end
    
    def mashup(response)
      if response.code == 200
        if response.is_a?(Hash)
          hash = Hashie::Mash.new(response)
        else
          if response.first.is_a?(Hash)
            hash = response.map{|item| Hashie::Mash.new(item)}
          else
            response
          end
        end
        
        puts "HASH STATUS"
        puts hash.status
        puts hash
        
        if hash.status == "OK" or hash.status == "ZERO_RESULTS"
          puts "Going to return hash"
          return hash
        elsif hash.status == "REQUEST_DENIED"
          raise "Bad Google Places Request - request denied"
        elsif hash.status == "OVER_QUERY_LIMIT"
          raise "Bad Google Places Request - OVER QUERY LIMIT"
        elsif hash.status == "INVALID_REQUEST"
          raise "Bad Google Places Request - INVALID REQUEST"
        end
      else
        raise "Google Places API returned non-200 result"
      end
    end
end