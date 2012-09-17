class UserTour
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :user

  field :subscribed_tour_ids, :type => Array, :default => []
end