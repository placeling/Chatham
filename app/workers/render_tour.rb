class RenderTour
  @queue = :tour

  def self.perform(tour_id, target_url)
    @tour = Tour.find(tour_id)

    outdir = Rails.root.join('public', 'uploads', @tour.id.to_s+'.png')
    rasterize = Rails.root.join('lib', 'rasterize.js')

    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - Tour Creation: #{target_url} #{outdir}"
    output = `phantomjs --local-to-remote-url-access=yes --ignore-ssl-errors=yes #{rasterize} #{target_url} #{outdir}`
    RESQUE_LOGGER.info "finished phantomjs"

    @tour.infographic = File.open(outdir)

    @tour.rendered = true
    @tour.save!

    if @tour.user.post_facebook? && Rails.env.production?
      # Resque.enqueue(FacebookPost, @tour.user.id, "placeling:create", {:tour => @tour.og_path})
      #commenting this out for now, was causing an error
    end

    track! :tour_created
  end
end
