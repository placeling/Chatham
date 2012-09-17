class AddSubscribedTours < Mongoid::Migration
  def self.up
    users = User.all()
    
    users.each do |user|
      if !user.user_tour
        user.create_user_tour
      end
      
      user.save
    end
    
  end

  def self.down
  end
end