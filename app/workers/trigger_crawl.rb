class TriggerCrawl
  @queue = :blog

  def self.perform()
    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - Kicking off blog jobs"

    Blogger.where(:activated => false).and(:last_updated.lt => 1.day.ago).limit(100).each do |blogger|
      Resque.enqueue(CrawlBlog, blogger.id)
    end
  end
end