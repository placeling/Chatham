class AddFirstRunSettings < Mongoid::Migration
  def self.up
    
    ca = ClientApplication.find("4e73c371a6f1ca1278000003") #nina
    
    User.all.each do |user|
      puts "Attaching first run info to #{user.username}"
      user.attach_first_run
      
      user.first_run.search = false
      user.first_run.placemark = false
      user.first_run.map = false
      
      if ca.tokens.where(:uid => user.id).entries.count == 0
        user.first_run.dismiss_app_ad = false
        user.first_run.downloaded_app = false
      else
        user.first_run.dismiss_app_ad = true
        user.first_run.downloaded_app = true
      end
      
      user.save
    end
  end

  def self.down
  end
end