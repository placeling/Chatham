class AddWeekInReview < Mongoid::Migration
  def self.up
    User.all.each do |user|
      puts "Attaching week in review to #{user.username}"
      
      user.user_settings.week_in_review_email = true
      
      user.save
    end
  end

  def self.down
  end
end