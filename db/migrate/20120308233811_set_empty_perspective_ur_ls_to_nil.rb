class SetEmptyPerspectiveUrLsToNil < Mongoid::Migration
  def self.up
    persps = Perspective.all()
    persps.each do |persp|
      if persp.url && persp.url.length == 0
        persp.url = nil
        persp.save
      end
    end
  end

  def self.down
  end
end