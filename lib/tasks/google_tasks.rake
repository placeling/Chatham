
namespace "google" do


  desc "Finds places that are more than a month old and updates them"
  task :update_places => :environment do

    places = Place.where( :updated_at.lt => 1.month.ago )

    puts places.count

  end
end
