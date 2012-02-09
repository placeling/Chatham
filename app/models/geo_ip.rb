class GeoIP
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Twitter::Extractor
  
  field :ip_start, :type => Integer
  field :ip_end,   :type => Integer
  field :lat,      :type => Float
  field :lng,      :type => Float
  
  index :ip_start
  index :ip_end
  
  def self.geo_from_ip(ip_address)
    ip_parts = ip_address.split(".")
    ip_number = (ip_parts[0].to_i * 256 * 256 * 256) + (ip_parts[1].to_i * 256 * 256) + (ip_parts[2].to_i * 256) + ip_parts[3].to_i
    
    target = GeoIP.where({:ip_start.lte => ip_number, :ip_end.gte => ip_number}).first()
    
    return target
  end
end
