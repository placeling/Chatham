require 'sitemap_generator/tasks'

class RegenerateSiteMap
  @queue = :admin
  def self.perform()
    if Rails.env.production?
    SitemapGenerator::Utilities.clean_files
    SitemapGenerator::Interpreter.run(:config_file => ENV["CONFIG_FILE"], :verbose => false)
    SitemapGenerator::Sitemap.ping_search_engines
    end

  end
end