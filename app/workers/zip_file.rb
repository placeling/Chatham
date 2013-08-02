require 'rubygems'
require 'zip/zip'

require 'open-uri'


class ZipFile
  @queue = :zip

  def self.perform(user_id)

    user = User.find(user_id)
    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - Outputting user #{user.username}, #{user.id}"

    zipfile_name = "#{Rails.root}/public/uploads/#{user.username}_placeling.zip"

    if user.escape_pod
      return
    end

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
                  perspective.pictures.each_with_index do |pic,i|
                    xml.filename "#{perspective.place.slug}_#{i}.jpg"
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

      user.perspectives.each do |p|
        p.pictures.each_with_index do |photo, i|
          puts photo.main_url

          begin
          photofile = URI.parse( photo.main_url ).read
          #zipfile.add("#{photo.id}.jpg", photo.main_url)
          zipfile.put_next_entry("#{p.place.slug}_#{i}.jpg")

          zipfile.print( photofile )
          rescue
          end


        end
      end
    end

    user.escape_pod = true
    user.save
  end
end