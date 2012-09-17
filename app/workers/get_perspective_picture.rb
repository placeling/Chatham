class GetPerspectivePicture
  @queue = :perspective_queue

  def self.perform(perspective_id, photo_urls)
    @perspective = Perspective.find(perspective_id)

    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - Grabbing #{@perspective.user.username}'s photos for perspectives: #{@perspective.id}\n#{photo_urls.join("\n")}"
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
          uri = URI(photo_url)

          if uri.host == "www.urbanspoon.com"
            break #special case, these give 403 errors
          end

          picture.remote_url = photo_url # for us, to keep track
          picture.remote_image_url = photo_url
          picture.save
        rescue => ex
          Airbrake.notify(ex, {:error_message => "Problem loading url #{photo_url}"})
          @perspective.pictures.delete(picture)
        end
      end
    end
  end
end