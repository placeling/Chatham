class UserSetting
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :user

  field :new_follower_notify, :type => Boolean, :default => true
  field :remark_notify, :type => Boolean, :default => true
  field :facebook_friend_notify, :type => Boolean, :default => true
  field :near_highlighted_notify, :type => Boolean, :default => true

  field :new_follower_email, :type => Boolean, :default => false
  field :remark_email, :type => Boolean, :default => false
  field :facebook_friend_email, :type => Boolean, :default => false
  field :weekly_email, :type => Boolean, :default => true

  field :question_updates_email, :type => Boolean, :default => true

  field :facebook_friend_check, :type => Boolean, :default => false

  field :emailed_stuff, :type => Array, :default => []

end