require 'google_places'

class CitynameFinder

  def self.getCity(lat, lng)

    rgp = GoogleReverseGeocode.new

    if lat ==0 and lng ==0
      return ""
    else
      raw_addresses = rgp.raw_reverse_geocode(lat, lng)

      if raw_addresses && raw_addresses.length > 0
        address_dict = CitynameFinder.getAddressDict( raw_addresses.first )

        if address_dict.has_key?('province') && address_dict.has_key?('city') && address_dict.has_key?('country')
          "#{address_dict['city']}, #{address_dict['province']}, #{address_dict['country']}"
        elsif address_dict.has_key?('city') && address_dict.has_key?('country')
          "#{address_dict['city']}, #{address_dict['country']}"
        end

      else
        return ""
      end
    end
  end



  def self.getAddressDict( raw_address )

    address_dict = {}
    for element in raw_address.address_components
      if element.types.include?("locality")
        address_dict['city'] = element.long_name
      elsif element.types.include?("administrative_area_level_1")
        address_dict['province'] = element.short_name
      elsif element.types.include?("country")
        address_dict['country'] = element.long_name
      end

    end

    return address_dict

  end
end
