require 'oauth'

class ClientApplication
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia #doesnt actually delete on .delete, only .delete! or .destroy!

  field :name,          :type => String
  field :url,           :type => String
  field :support_url,   :type => String
  field :callback_url,  :type => String
  field :key,           :type => String
  field :secret,        :type => String
  field :description,   :type => String

  field :token_creation_lock, :type => Boolean, :default => false
  field :xauth_enabled,  :type => Boolean, :default =>true

  index :key, :unique => true

  belongs_to :user
  has_many :tokens, :class_name => 'OauthToken'
  has_many :access_tokens
  has_many :oauth2_verifiers
  has_many :oauth_tokens

  #listed mostly in case we find a malicious client application, foreign keys stored in other.
  has_many :places
  has_many :perspectives

  validates_presence_of :name, :url, :key, :secret
  validates_uniqueness_of :key
  before_validation :generate_keys, :on => :create

  validates_format_of :url, :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i
  validates_format_of :support_url, :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i, :allow_blank=>true
  validates_format_of :callback_url, :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i, :allow_blank=>true

  attr_accessor :token_callback_url

  def self.find_token(token_key)
    token = OauthToken.where(:token => token_key)
    if token && token.authorized?
      token
    else
      nil
    end
  end

  def self.find_by_key(consumer_key)
    ClientApplication.where(:key => consumer_key).first
  end

  def self.verify_request(request, options = {}, &block)
    begin
      signature = OAuth::Signature.build(request, options, &block)
      return false unless OauthNonce.remember(signature.request.nonce, signature.request.timestamp)
      value = signature.verify
      value
    rescue OAuth::Signature::UnknownSignatureMethod => e
      false
    end
  end

  def oauth_server
    @oauth_server ||= OAuth::Server.new("http://your.site")
  end

  def credentials
    @oauth_client ||= OAuth::Consumer.new(key, secret)
  end

  # If your application requires passing in extra parameters handle it here
  def create_request_token(params={})
    if !self.token_creation_lock || params[:token_creation_override]
      RequestToken.create :client_application => self, :callback_url=>self.token_callback_url
    else
      return nil
    end
  end

  def delete!
    logger.warn("Delete! (the permanent one) attempted to be called on client_application")
    self.delete #non-permanent version
  end

  protected
  def generate_keys
    self.key = OAuth::Helper.generate_key(40)[0,40]
    self.secret = OAuth::Helper.generate_key(40)[0,40]
  end
end
