class FixUserTimestamps < Mongoid::Migration
  def self.up
    for user in User.all
        youngest = Time.now
        for perspective in user.perspectives
          if perspective.created_at <youngest
            youngest = perspective.created_at
          end
        end
        user.created_at = youngest
        user.save
    end
  end

  def self.down
  end
end
