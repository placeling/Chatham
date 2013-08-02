require 'rubygems'
require 'zip/zip'

require 'open-uri'


class ZipFile
  @queue = :zip

  def self.perform(user_id)

    user = User.find(user_id)
    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - Outputting user #{user.username}, #{user.id}"

    zipfile_name = "#{Rails.root}/public/uploads/#{user.username}_placeling.zip"

    Zip::ZipOutputStream.open(zipfile_name) do |zipfile|
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.root {
          xml.username user.username
          xml.fullname user.fullname
          xml.email user.email
          xml.city user.city
          xml.location user.loc
          xml.url user.url
          xml.profile_pic "profile.png"

          xml.placemarks {
            user.perspectives.each do |perspective|
              xml.place {
                xml.name perspective.place.name
                xml.city perspective.place.city_data
                xml.location perspective.place.loc
                xml.google_id perspective.place.google_id
                xml.google_place_url perspective.place.google_url
                xml.notes perspective.memo
                if perspective.url
                  xml.url perspective.url
                end
                xml.pictures {
                  perspective.pictures.each do |pic|
                    xml.filename "#{pic.id}.jpg"
                  end
                }

                xml.datetime perspective.created_at
              }
            end
          }

        }

      end

      zipfile.put_next_entry("#{user.username}_data.xml")
      zipfile.print( builder.to_xml )

      zipfile.put_next_entry("profile.png")
      zipfile.print( URI.parse( user.main_url ).read )

      user.perspectives.limit(1).each do |p|
        p.pictures.each do |photo|
          puts photo.main_url

          #zipfile.add("#{photo.id}.jpg", photo.main_url)
          zipfile.put_next_entry("#{photo.id}.jpg")
          zipfile.print( URI.parse( photo.main_url ).read )

        end
      end
    end



  end
end