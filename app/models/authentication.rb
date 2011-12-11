class Authentication
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps

  field :p, :as => :provider, :type =>String
  field :uid, :type => String
  field :token, :type => String
  field :expiry, :type =>String

  field :dict, :type => Hash

  belongs_to :user

  index :p
  index :uid

  validates_uniqueness_of :uid

  def self.find_by_provider_and_uid(provider,id)
    self.where(:uid =>id).and(:p=>provider).first
  end

end