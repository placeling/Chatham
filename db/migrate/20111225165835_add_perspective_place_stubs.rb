class AddPerspectivePlaceStubs < Mongoid::Migration
  def self.up
    #re-saving all perspectives should do it
    for perspective in Perspective.all
      if perspective.place_stub.nil?
        perspective.get_place_data
        perspective.save!
      end
      puts "#{perspective.user.username}'s perspective for - #{perspective.place_stub.name}"
    end

    Rake::Task['db:mongoid:create_indexes'].invoke
  end

  def self.down
  end
end