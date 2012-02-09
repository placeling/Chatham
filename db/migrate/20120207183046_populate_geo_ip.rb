class PopulateGeoIp < Mongoid::Migration
  def self.up
    counter = 1
    file = File.new("assets/GeoIPCity.csv", "r")
    while (line = file.gets)
      # Skip first line as header
      if counter > 1
        geoip = GeoIP.new
        
        parts = line.split(",")
        
        start_ip = parts[0]
        end_ip = parts[1]
        
        lat = parts[6]
        lng = parts[7]
        
        start_ip_parts = start_ip.split(".")
        start_ip_number = (start_ip_parts[0].to_i * 256 * 256 * 256) + (start_ip_parts[1].to_i * 256 * 256) + (start_ip_parts[2].to_i * 256) + start_ip_parts[3].to_i
        
        end_ip_parts = end_ip.split(".")
        end_ip_number = (end_ip_parts[0].to_i * 256 * 256 * 256) + (end_ip_parts[1].to_i * 256 * 256) + (end_ip_parts[2].to_i * 256) + end_ip_parts[3].to_i
        
        geoip.ip_start = start_ip_number
        geoip.ip_end = end_ip_number
        geoip.lat = lat.to_f
        geoip.lng = lng.to_f
        
        geoip.save
      end
      counter += 1
    end
    file.close
  end

  def self.down
  end
end