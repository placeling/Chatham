require 'google_places'

class CitynameFinder

  def self.getCity(lat, lng)

    rgp = GoogleReverseGeocode.new

    if lat ==0 and lng ==0
      return ""
    else
      raw_addresses = rgp.raw_reverse_geocode(lat, lng)

      if raw_addresses && raw_addresses.length > 0
        address_dict = GooglePlaces.getAddressDict( raw_addresses.first.address_components )

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
end
