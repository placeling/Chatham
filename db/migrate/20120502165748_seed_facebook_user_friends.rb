class SeedFacebookUserFriends < Mongoid::Migration
  def self.up
    User.all.each do |user|
      puts "Inspecting #{user.username} for facbookness"
      if user.facebook
        puts "\tfound, kicking off facebook friend finding for #{user.username}"
        Resque.enqueue(NewFacebookUser, user.id)
      end

    end
  end

  def self.down
  end
end