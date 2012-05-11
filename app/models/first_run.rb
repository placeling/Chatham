class FirstRun
  include Mongoid::Document
  include Mongoid::Timestamps
  
  embedded_in :user
  
  field :search, :type => Boolean, :default => false
  field :placemark, :type => Boolean, :default => false
  field :map, :type => Boolean, :default => false
  
  field :dismiss_app_ad, :type => Boolean, :default => false
  field :downloaded_app, :type => Boolean, :default => false
end