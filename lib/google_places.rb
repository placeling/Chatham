require 'json'

class GooglePlaces
  include HTTParty
  #debug_output $stdout

  # api docs: http://code.google.com/apis/maps/documentation/places/
  base_uri "https://maps.googleapis.com/maps/api/place"

  def initialize()
    @api_key = CHATHAM_CONFIG['google_api']
  end


  def self.getAddressDict(raw_address)

    address_dict = {}
    for element in raw_address
      if element.types.include?("locality")
        address_dict['city'] = element.long_name
      elsif element.types.include?("administrative_area_level_1")
        address_dict['province'] = element.short_name
      elsif element.types.include?("country")
        address_dict['country'] = element.long_name
      elsif element.types.include?("street_number")
        address_dict['number'] = element.short_name
      elsif element.types.include?("route")
        address_dict['street'] = element.long_name
      end
    end

    return address_dict
  end


  def get_place(reference, sensor = true, language ="en")
    #radis is in meters

    options = {
        :reference => reference,
        :sensor => sensor
    }

    raw_response = self.class.get("/details/json", :query => options.merge(self.default_options))
    response = mashup(raw_response)
    if response && response.status = "OK"
      mashup = response.result
      mashup.html_attributions = response.html_attributions
      return mashup
    else
      pp raw_response
      return nil
    end

  end

  def check_in(google_id, sensor = false)
    place = Place.find_by_google_id(google_id)

    if place.nil?
      return "Invalid location"
    end

    if !place.google_ref.nil?
      options = {
          :sensor => sensor
      }

      ref = {:reference => place.google_ref}

      result = mashup(self.class.post("/check-in/json",
                                      :query => options.merge(self.default_options),
                                      :body => ref.to_json))

      return result["status"]
    else
      return "No google reference"
    end
    return false
  end

  def find_nearby(x, y, radius, query = nil, sensor = true, type_array =[], language ="en")
    #radius is in meters

    location = [x.round(4), y.round(4)].join(',')

    options = {
        :location => location,
        :sensor => sensor,
        :types => type_array.join("|")
    }

    if !query.nil?
      #override radius to something larger
      options[:name] = query
      options[:radius] = 4000
    else
      #TEST: cap radius at 100m
      radius = [50, [200, radius].min].max
      options[:radius] = radius
    end

    results = mashup(self.class.get("/search/json", :query => options.merge(self.default_options))).results

    for place in results
      if place.types.include?("political") or place.types.include?("route")
        results.delete(place)
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
    {:key => @api_key}
  end

  def mashup(response)
    if response.code == 200
      if response.is_a?(Hash)
        hash = Hashie::Mash.new(response)
      else
        if response.first.is_a?(Hash)
          hash = response.map { |item| Hashie::Mash.new(item) }
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

