class SetPerspectiveEmptyStatus < Mongoid::Migration
  def self.up
    perps = Perspective.all()
    perps.each_with_index do |perp, index|
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