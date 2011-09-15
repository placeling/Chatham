require 'json'

class GooglePlaces
  include HTTParty
  #debug_output $stdout
  
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

  def find_nearby(x, y, radius, query = nil, sensor = true, type ="", language ="en")
    #radius is in meters

    location = [x,y].join(',')

    options = {
      :location => location,
      :radius => radius,
      :sensor => sensor
    }

    if !query.nil?
      options[:name] = query
    end

    results = mashup( self.class.get("/search/json", :query => options.merge(self.default_options)) ).results

    for place in results
      if place.types.include?( "political" )
        results.delete( place )
      end
    end

    return results
  end

  def create(x, y, radius, name, category, sensor=false, language="en")
    # Known issue: if try a category of "other", will fail
    # Logged bug #3622 w/ Google
    # http://code.google.com/p/gmaps-api-issues/issues/detail?id=3622&sort=-id&colspec=ID%20Type%20Status%20Introduced%20Fixed%20Summary%20Stars%20ApiType%20Internal
    
    options = {
      :sensor => sensor
    }
    
    body = {
      :location => {
        :lat => x.to_f,
        :lng => y.to_f
      },
      :accuracy => radius,
      :name => name,
      :types => [category],
      :language => language
    }
    
    # hardcode all "other" to "establishment" as workaround for issue #3622
    if category == "other"
      body[:types] = ["establishment"]
    end
    
    results = mashup(self.class.post("/add/json",
                                    :query => options.merge(self.default_options),
                                    :body => body.to_json))
    
    return results
  end
  
  def delete(reference, sensor = false)
    
    options = {
      :sensor => sensor
    }
    
    ref = {:reference => reference}
    
    results = mashup(self.class.post("/delete/json",
                                    :query => options.merge(self.default_options),
                                    :body => ref.to_json))
    
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

