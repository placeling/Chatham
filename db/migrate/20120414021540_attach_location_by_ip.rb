class AttachLocationByIp < Mongoid::Migration
  def self.up
    geo = GeoIP.new("#{Rails.root}/config/GeoIPCity.dat")

    User.all.each do |user|

      if user.location.nil?
        puts "#{user.username} has no location"
        if user.last_sign_in_ip
          puts "\tlast signin from #{user.last_sign_in_ip}"

          loc = geo.city( user.last_sign_in_ip )

          if loc
            puts "\tassigning lat/lng of #{loc.latitude},#{loc.longitude}"
            user.location = [loc.latitude, loc.longitude]
            user.save
          end
        end
      end
    end


  end

  def self.down
  end
end