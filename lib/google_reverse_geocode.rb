require 'json'

class GoogleReverseGeocode
  include HTTParty
  #debug_output $stdout
  
  # reverse geocoding docs: http://code.google.com/apis/maps/documentation/geocoding/
  base_uri "http://maps.googleapis.com/maps/api/geocode"
  
  def reverse_geocode(lat, lng)
    options = {
      :sensor => false,
      :latlng => lat.to_s + "," + lng.to_s
    }
    
    result = mashup(self.class.get("/json", :query => options))
    
    found_address = nil
    if result.status == "OK"
      result.results.each do |entry|
        if entry.types.include? "street_address"
          found_address = entry
          break
        end
      end
    end
    
    return found_address
  end

  def raw_reverse_geocode(lat, lng)
    options = {
      :sensor => false,
      :latlng => lat.to_s + "," + lng.to_s
    }

    result = mashup(self.class.get("/json", :query => options)).results

    return result
  end

  
  protected
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
          raise "Bad Reverse Geocode Request - request denied"
        elsif hash.status == "OVER_QUERY_LIMIT"
          raise "Bad Reverse Geocode Request - OVER QUERY LIMIT"
        elsif hash.status == "INVALID_REQUEST"
          raise "Bad Reverse Geocode Request - INVALID REQUEST"
        end
      else
        raise "Google Reverse Geocode API returned non-200 result"
      end
    end
end
