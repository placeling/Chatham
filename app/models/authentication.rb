class Authentication
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps

  field :p, :as => :provider, :type => String
  field :uid, :type => String
  field :token, :type => String
  field :expiry, :type => String
  field :expires_at, :type => Time
  field :secret, :type => String

  field :dict, :type => Hash

  belongs_to :user

  index :uid
  index :user_id

  after_create :social_graph_jobs

  def self.find_by_provider_and_uid(provider, id)
    self.where(:uid => id).and(:p => provider).first
  end

  def as_json(options={})
    attributes = {:provider => self['p'], :uid => self['uid'], :token => self['token'],
                  :expiry => self.expiry, :secret => self.secret}

    if self.expiry.nil?
      attributes[:expiry] = 1.month.from_now
    end

    attributes
  end

  def social_graph_jobs
    if provider == "facebook"
      Resque.enqueue(NewFacebookUser, self.user.id)
    end

    if provider == "facebook" && !self.user.avatar? && !Rails.env.test? #no need for this in test
      self.user.remote_avatar_url = self.user.facebook.get_picture("me", :type => "large") #go get facebook profile
      self.user.save
    end

  end

end