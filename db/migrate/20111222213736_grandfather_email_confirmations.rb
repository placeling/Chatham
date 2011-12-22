class GrandfatherEmailConfirmations < Mongoid::Migration
  def self.up
    for user in User.all
      user.confirmed_at = user.created_at
      puts user.username
      user.save
    end
  end

  def self.down
  end
end