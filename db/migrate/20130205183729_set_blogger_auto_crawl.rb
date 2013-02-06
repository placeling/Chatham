class SetBloggerAutoCrawl < Mongoid::Migration
  def self.up
    Blogger.all.each do |blogger|
      blogger.auto_crawl = true
      blogger.save
    end
  end

  def self.down
  end
end