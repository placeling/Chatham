class UserRecommendation
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :user

  field :recommended_ids, :type => Array, :default => []
end