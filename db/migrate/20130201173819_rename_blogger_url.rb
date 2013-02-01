class RenameBloggerUrl < Mongoid::Migration
  def self.up
    Blogger.all.each do |blogger|
      blogger.url = blogger.base_url
      blogger.save
    end
  end

  def self.down
  end
end