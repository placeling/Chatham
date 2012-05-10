require 'cityname_finder'
require 'redis_helper'

class User
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include RedisHelper

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable, :confirmable, :registerable

  #before_validation :fix_location
  after_validation :set_downcase_username
  # For updating avatar see http://railscasts.com/episodes/182-cropping-images
  after_update :process_avatar, :if => :cropping?
  after_create :track_signup

  FEED_COUNT=30
  FEED_LENGTH=240
  
  def cropping?
    !x.blank? && !y.blank? && ! w.blank? && !h.blank?
  end

  def track_signup
    track! :signup
  end
  
  def process_avatar
    self.avatar.recreate_versions!
    self.x = nil
    self.y = nil
    self.w = nil
    self.h = nil
    self.save
  end
  
  field :username,      :type =>String
  field :du, :as => :downcase_username, :type => String
  field :fullname,      :type =>String
  alias :login :username
  field :email,         :type =>String
  field :pc, :as => :perspective_count,  :type=>Integer, :default => 0 #property for easier lookup of of top users
  field :creation_environment, :type => String, :default => "production"

  field :loc, :as => :location, :type => Array #meant to be home location, used at signup?
  field :city, :type => String, :default => ""

  field :description, :type => String, :default => ""
  field :admin,       :type => Boolean, :default => false

  field :url, :type => String, :default => ""

  field :thumb_cache_url, :type => String
  field :main_cache_url, :type => String
  field :confirmed_at, :type =>DateTime

  field :ios_notification_token, :type =>String
  
  # For avatar cropping
  # Initial position of cropping + dimensions
  field :x, :type => Float
  field :y, :type => Float
  field :w, :type => Float
  field :h, :type => Float
  
  has_many :perspectives, :foreign_key => 'uid'
  has_many :places #ones they created
  has_many :authentications

  mount_uploader :avatar, AvatarUploader, mount_on: :avatar_filename

  has_and_belongs_to_many :following, class_name: 'User', inverse_of: :followers, autosave: true
  has_and_belongs_to_many :followers, class_name: 'User', inverse_of: :following

  has_many :client_applications, :foreign_key =>'uid'
  has_many :tokens, :class_name=>"OauthToken",:order=>"authorized_at desc", :foreign_key =>'uid'

  embeds_one :activity_feed
  embeds_one :user_setting
  accepts_nested_attributes_for :user_setting

  validate :acceptable_name, :on => :create
  validate :acceptable_password
  validates_presence_of :username
  validates_presence_of :email
  validates_format_of :username, :with => /\A[a-zA-Z0-9]+\Z/, :message => "must only contain letters and number"
  validates_format_of :email, :with => /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/, :message => "is not valid"
  validates_length_of :username, :within => 3..20, :too_long => "must be shorter", :too_short => "must be longer"
  validates_uniqueness_of :username, :email, :case_sensitive => false
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me, :admin, :description, :url, :user_setting_attributes, :city
  
  index :unm
  index :email
  index :pc
  index [[ :loc, Mongo::GEO2D ]], :min => -180, :max => 180
  index :fp, :background => true
  index :du

  before_save :cache_urls
  before_save :get_city

  before_create :attach_subdocs
  after_create :follow_defaults

  def get_city
    if self.location != nil && self.location != [0,0] && self.city == ""
      self.city =  CitynameFinder.getCity( self.location[0], self.location[1] )
    end
  end

  def attach_subdocs
    if !self.activity_feed
      self.create_activity_feed
    end

    if !self.user_setting
      self.create_user_setting
    end
  end

  def follow_defaults
    other = User.find_by_username( 'citysnapshots' )
    if other
      self.follow other
    end
  end

  def set_downcase_username
    self.downcase_username = self.username.downcase
  end

  def acceptable_name
    if NAUGHTY_WORDS.include? self.username
      errors.add :username, I18n.t('user.reserved_username')
    end

    if RESERVED_USERNAMES.include? self.username
      errors.add :username, I18n.t('user.reserved_username')
    end
  end

  def acceptable_password
    if SHITTY_PASSWORDS.include? @password
      errors.add :password, I18n.t('user.shitty_password')
    end
  end

  def fix_location
    #this is broken until we upgrade to rails 3.1
    if self.location[0]
      self.location[0] = number_with_precision(self.location[0], :precision => 2)
    end
    if self.location[1]
      self.location[1] = number_with_precision(self.location[1], :precision => 2)
    end
  end

  def cache_urls
    self.creation_environment = Rails.env
    self.thumb_cache_url = self.avatar_url(:thumb)
    self.main_cache_url =  self.avatar_url(:main)
  end

  def thumb_url
    url = nil
    if Rails.env == self.creation_environment
      url = self.avatar_url(:thumb)
    elsif thumb_cache_url
      url =  thumb_cache_url
    end

    if url
      return url
    else
      return "https://www.placeling.com/images/default_profile.png"
    end
  end

  def main_url
    url = nil
    if Rails.env == self.creation_environment
      url = self.avatar_url(:main)
    elsif main_cache_url
      url =  main_cache_url
    end

    if url
      return url
    else
      return "https://www.placeling.com/images/default_profile.png"
    end
  end
  
  def self.top_users( top_n )
    self.desc( :pc ).limit( top_n )
  end

  def self.top_nearby( lat, lng, top_n )
    User.where(:loc.within => {"$center" => [[lat,lng],0.3]}).
        desc( :pc ).
        limit( top_n ).entries
  end

  def self.find_by_username( username )
    self.where( :du => username.downcase ).first
  end

  def self.search_by_username( username )
    self.where( :du => /^#{username.downcase}/i).limit( 20 )
  end

  def remove_tokens_for( client_application )
    self.tokens.where(:cid =>client_application.id).delete_all
  end

  def perspective_for_place( place )
    place.perspectives.where(:uid => self.id).first
  end

  def following_perspectives_for_place( place )
    place.perspectives.where(:uid.in => self.following_ids).entries
  end

  def is_admin?
    self.admin
  end

  def to_param
    #when routing, this makes the :id really the username
    self.username
  end

  def star( perspective )

    place = perspective.place
    user_perspective = self.perspective_for_place( place )

    #starring a perspective triggers a bookmark of it
    if user_perspective.nil?
      user_perspective= place.perspectives.build()
      user_perspective.user = self
      user_perspective.modified_at = Time.now #prevents being sent to feed, covered in "star activity" below
    end

    user_perspective.favourite_perspective_ids << perspective.id
    user_perspective.save

    perspective.starring_users << self.id
    perspective.save

    return user_perspective
  end

  def unstar( perspective )

    place = perspective.place
    user_perspective = self.perspective_for_place( place )

    user_perspective.favourite_perspective_ids.delete( perspective.id )
    user_perspective.save

    perspective.starring_users.delete( self.id )
    perspective.save
  end

  def follows?( user )
    following.include?( user )
  end

  def follow( user )
    if self.id != user.id && !self.following.include?(user)
      self.following << user
    end
  end

  def unfollow( user )
    self.following.to_a #hack to ensure in memory, not a problem for mongodb 2.0  https://github.com/mongoid/mongoid/issues/1369
    self.following.delete( user )
  end

  def build_activity
    if !self.activity_feed
      self.create_activity_feed
    end

    chunk = self.activity_feed.head_chunk

    activity = chunk.activities.build
    activity.actor1 = self.id
    activity.username1 = self.username
    activity.thumb1 = self.thumb_url

    return activity
  end

  def user_settings

    if self.user_setting
      return self.user_setting
    else
      self.user_setting = UserSetting.new
      return self.user_setting
    end
  end


  def as_json(options={})
    #these could eventually be paginated #person.posts.paginate(page: 2, per_page: 20)
    attributes = {:id =>self['_id'], :username => self['username'],  :perspectives_count =>self['pc'],
                  :url => self.url, :description => self.description,
                  :thumb_url => thumb_url, :main_url => main_url, :city =>self.city, :fullname =>self.fullname }

    attributes = attributes.merge(:follower_count => followers.count, :following_count => following.count)
    #photo id is same as user, for now
    attributes = attributes.merge(:picture => {:id => self['_id'], :thumb_url => thumb_url, :main_url => main_url, :city =>self.city} )

    attributes = attributes.merge( :lat => self.location[0], :lng=> self.location[1]  ) unless self.location.nil?

    if options[:current_user]
      current_user =options[:current_user]
      #check against raw ids so it doesnt have to go back to db
      following = self['follower_ids'].include?( options[:current_user].id ) ||self.id == options[:current_user].id
      follows_you = self['following_ids'].include?( options[:current_user].id )
      attributes = attributes.merge(:following => following, :follows_you => follows_you, :location=>self[:loc])
      if self.id == current_user.id
        for auth in current_user.authentications
          attributes = attributes.merge(auth.provider => auth)
        end
        attributes = attributes.merge(:auths => self.authentications)
      end
    else
      current_user = nil
    end

    if (options[:perspectives] == :location)
      attributes.merge(:perspectives => self.perspectives.near(:loc => options[:location] ).includes(:place).as_json({:user_view=>true,:current_user =>current_user })  )
    elsif (options[:perspectives] == :created_by )
      attributes.merge(:perspectives => self.perspectives.descending(:created_at).includes(:place).limit(10).as_json({:user_view=>true,:current_user =>current_user }) )
    else
      attributes
    end
  end

  def apply_omniauth( omniauth )
    self.email = omniauth['user_info']['email'] if email.blank?
    
    if username.blank?
      if omniauth['provider'] == "facebook" && omniauth['user_info']['nickname']
        username = omniauth['user_info']['nickname'].gsub(/\W+/, "")
      else
        username = omniauth['user_info']['name'].gsub(/\W+/, "")
      end
      
      user = User.find_by_username(username)
      i = 1
      baseusername = username
      
      while user
        username = baseusername + i.to_s
        user = User.find_by_username(username)
        i += 1
      end
      
      self.username = username
    end
    
    
  end

  def remark_notification?
    !ios_notification_token.nil? && self.user_settings.remark_notify
  end

  def follow_notification?
    !ios_notification_token.nil? && self.user_settings.new_follower_notify
  end

  def follow_email?
    self.confirmed? && self.user_settings.new_follower_email
  end

  def remark_email?
    self.confirmed? && self.user_settings.remark_email
  end

  def weekly_email?
    self.confirmed? && self.user_settings.weekly_email
  end

  def ios_notification_token
    return nil unless !self[:ios_notification_token].nil?
    res = self[:ios_notification_token].scan(/\<(.+)\>/).first
    unless res.nil? || res.empty?
      return res.first
    end
    return self[:ios_notification_token]
  end

  def facebook
    for auth in self.authentications
      if auth.provider == 'facebook' && !auth.token.nil?
        return FbGraph::User.me( auth.token )
      end
    end
    return nil

   # @fb_user ||= FbGraph::User.me(self.authentications.find_by_provider('facebook').token)
  end

  # get latest feed using reverse range lookup of sorted set
  # then decode raw JSON back into Ruby objects
  def feed(obj=true, count=FEED_COUNT)
    results=$redis.zrevrange key(:feed), 0, count
    if obj && results.size > 0
      results.collect {|r| Activity.decode(r)}
    else
      results
    end
  end

  # get older statuses by using reverse range by score lookup
  def ofeed(max, obj=true, id=self.id_s, limit=FEED_COUNT, scores=false)
    results=$redis.zrevrangebyscore(key(:feed), "(#{max}", "-inf", :limit => [0, limit], :with_scores => scores)
    if obj && results.size > 0
      results.collect {|r| Activity.decode(r)}
    else
      results
    end
  end

  # there may be a more efficient way to do this
  # but I check the length of the set
  # then I get the score of the last value I want to keep
  # then remove all keys with a lower score
  def trim_feed(id=self.id_s, location="feed", indx=FEED_LENGTH)
    k = key(:feed)
    if ( $redis.zcard k ) >= indx
      n = indx - 1
      if (r = $redis.zrevrange k, n, n, :with_scores => true)
        $redis.zremrangebyscore k, "-inf", "(#{r.last}"
      end
    end
  end

  protected

  def self.find_for_database_authentication(conditions)
    login = conditions.delete(:login)
    self.any_of({ :du => login.downcase }, { :email => login }).first
  end

end
