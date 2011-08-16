class GooglePlaces
  include HTTParty

  # api docs: http://code.google.com/apis/maps/documentation/places/
  base_uri "https://maps.googleapis.com/maps/api/place"

  def initialize()
    @api_key = CHATHAM_CONFIG['google_api']
  end

  def get_place(reference, sensor = true, language ="en")
    #radis is in meters

    options = {
      :reference => reference,
      :sensor => sensor
    }

    mashup( self.class.get("/details/json", :query => options.merge(self.default_options)) ).result

  end

  def find_nearby(x, y, radius, name = nil, sensor = true, type ="", language ="en")
    #radis is in meters

    location = [x,y].join(',')

    options = {
      :location => location,
      :radius => radius,
      :sensor => sensor
    }

    if !name.nil?
      options[:name] = name
    end

    results = mashup( self.class.get("/search/json", :query => options.merge(self.default_options)) ).results

    for place in results
      if place.types.include?( "political" )
        results.delete( place )
      end
    end

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

        if hash.status == "OK" or hash.status == "ZERO_RESULTS"
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

