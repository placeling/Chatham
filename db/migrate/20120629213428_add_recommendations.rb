class AddRecommendations < Mongoid::Migration
  def self.up
    users = User.all()
    
    users.each do |user|
      if !user.user_recommendation
        user.create_user_recommendation
      end
      
      user.save
    end
  end

  def self.down
  end
end