class RenderTour
  @queue = :tour
  
  def self.perform(tour_id, target_url)
    @tour = Tour.find(tour_id)
    
    outdir = Rails.root.join('public','uploads',@tour.id.to_s+'.png')
    rasterize = Rails.root.join('lib','rasterize.js')
    
    RESQUE_LOGGER.info "#{target_url} #{outdir}"
    output = `phantomjs #{rasterize} #{target_url} #{outdir}`
    RESQUE_LOGGER.info "finished phantomjs"
    
    @tour.infographic = File.open(outdir)
    
    @tour.rendered = true
    @tour.save!
  end
end
