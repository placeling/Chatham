class GetPerspectivePicture
    @queue = :perspective_queue
    def self.perform(perspective_id, photo_url)

      @perspective = Perspective.find( perspective_id )

      picture = @perspective.pictures.build()
      begin
        picture.remote_image_url = photo_url
        picture.remote_url = photo_url # for us, to keep track
        picture.save
      rescue => ex
        Airbrake.notify( ex )
        @perspective.pictures.delete(picture)
      end
    end
end