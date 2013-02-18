class SetBlogFeaturedDefaultFalse < Mongoid::Migration
  def self.up
    blogs = Blogger.all()
    blogs.each do |blog|
      blog.featured = false
      blog.save
    end
  end

  def self.down
  end
end