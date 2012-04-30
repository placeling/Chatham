class AttachUserSettings < Mongoid::Migration
  def self.up

    ca = ClientApplication.find("4e73c371a6f1ca1278000003") #nina

    User.all.each do |user|
      puts "Attaching settings to #{user.username}"
      user.attach_settings

      user.x = nil
      user.y = nil
      user.w = nil
      user.h = nil

      if ca.tokens.where(:uid => user.id).entries.count == 0
        puts "no iphone attached, switch to email stuff"
        user.user_settings.new_follower_notify = false
        user.user_settings.remark_notify = false

        user.user_settings.new_follower_email = true
        user.user_settings.remark_email =true
      end

      user.save
    end
  end

  def self.down
  end
end