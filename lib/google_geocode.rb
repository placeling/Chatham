require 'json'
require 'erb'
include ERB::Util

class GoogleGeocode
  include HTTParty
  #debug_output $stdout
  
  # geocoding docs: http://code.google.com/apis/maps/documentation/geocoding/
  base_uri "http://maps.googleapis.com/maps/api/geocode"
  
  def geocode(address_pieces)
    options = {
      :sensor => false,
      #:address => u(address_pieces.join(","))
      :address => address_pieces.join(",")
    }
    
    result = mashup(self.class.get("/json", :query => options))
    
    found_geocode = nil
    if result.status == "OK"
      result.results.each do |entry|
        if entry.geometry.include? "location":
          found_geocode = entry
          break
        end
      end
    end
    
    return found_geocode
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