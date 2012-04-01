class GetPerspectivePicture
    @queue = :perspective_queue
    def self.perform(perspective_id, photo_urls)
        @perspective = Perspective.find( perspective_id )

        for photo_url in photo_urls
          found = false
          for picture in @perspective.pictures
            if picture.remote_url && picture.remote_url == photo_url
              found = true
              break
            end
          end

          if !found
            picture = @perspective.pictures.build()
            begin
              picture.remote_url = photo_url # for us, to keep track
              picture.remote_image_url = photo_url
              picture.save
            rescue => ex
              Airbrake.notify( ex )
              @perspective.pictures.delete(picture)
            end
          end
        end
    end
end