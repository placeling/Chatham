class UserSetting
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :user

  field :new_follower_notify, :type => Boolean, :default => true
  field :remark_notify, :type => Boolean, :default => true

  field :new_follower_email, :type => Boolean, :default => false
  field :remark_email, :type => Boolean, :default => false
  field :weekly_email, :type => Boolean, :default => true

end