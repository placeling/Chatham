require 'google_places'

namespace "google" do

  desc "Finds places that are more than a month old and updates them"
  task :update_places => :environment do
    Resque.enqueue(GooglePlaceUpdate)
  end
end
