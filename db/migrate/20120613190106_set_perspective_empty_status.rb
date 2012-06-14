class SetPerspectiveEmptyStatus < Mongoid::Migration
  def self.up
    Perspective.all.each do |perp|
      if perp.empty_perspective?
        perp.empty = true
      else
        perp.empty = false
      end
      perp.save
    end
  end

  def self.down
  end
end