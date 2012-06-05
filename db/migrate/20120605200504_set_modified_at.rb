class SetModifiedAt < Mongoid::Migration
  def self.up
    Perspective.where(:modified_at => nil).each do |persp|
      persp.modified_at = persp.updated_at
      persp.timeless.save
    end
  end

  def self.down
  end
end