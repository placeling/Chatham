class UserSetting
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :user

  field :follow_email, :type =>Boolean, :default => true
  field :star_email, :type =>Boolean, :default => true

end