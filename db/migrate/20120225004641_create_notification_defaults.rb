class CreateNotificationDefaults < Mongoid::Migration
  def self.up
    users = User.all
    users.each do |user|
      user.new_follower_notify = true
      user.remark_notify = true
      user.save
    end
  end

  def self.down
  end
end