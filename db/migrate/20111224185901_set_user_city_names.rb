class SetUserCityNames < Mongoid::Migration
  def self.up
    for user in User.all
      user.get_city
      puts "#{user.username} - #{user.city}"
      user.save
      sleep 5
    end
  end

  def self.down
  end
end