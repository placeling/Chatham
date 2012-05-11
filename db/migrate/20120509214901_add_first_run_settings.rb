class AddFirstRunSettings < Mongoid::Migration
  def self.up
    User.all.each do |user|
      puts "Attaching first run info to #{user.username}"
      user.attach_first_run
      
      user.first_run.search = false
      user.first_run.placemark = false
      user.first_run.map = false
      
      user.first_run.dismiss_app_ad = false
      user.first_run.downloaded_app = false
      
      user.save
    end
  end

  def self.down
  end
end