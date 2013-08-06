require 'redis_helper'

class User
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include RedisHelper
  include ApplicationHelper

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable, :confirmable, :registerable

  FEED_COUNT=30
  FEED_LENGTH=240

  field :username, :type => String
  field :du, :as => :downcase_username, :type => String
  field :fullname, :type => String
  alias :login :username
  field :pc, :as => :perspective_count, :type => Integer, :default => 0 #property for easier lookup of of top users
  field :creation_environment, :type => String, :default => "production"
  field :ck, :type => String

  field :notification_count, :type => Integer, :default => 0

  field :escape_pod, :type => Boolean, :default => false
  field :want_email, :type => Boolean, :default => false

  ## Database authenticatable
  field :email, :type => String, :null => false, :default => ""
  field :encrypted_password, :type => String, :null => false, :default => ""

  ## Recoverable
  field :reset_password_token, :type => String
  field :reset_password_sent_at, :type => Time

  ## Rememberable
  field :remember_created_at, :type => Time

  ## Trackable
  field :sign_in_count, :type => Integer, :default => 0
  field :current_sign_in_at, :type => Time
  field :last_sign_in_at, :type => Time
  field :current_sign_in_ip, :type => String
  field :last_sign_in_ip, :type => String

  ## Confirmable
  field :confirmation_token, :type => String
  field :confirmed_at, :type => Time
  field :confirmation_sent_at, :type => Time
  field :unconfirmed_email, :type => String # Only if using reconfirmable

  ## Token authenticatable
  # field :authentication_token, :type => String
  field :third_party_id, :type => String

  field :loc, :as => :location, :type => Array #meant to be home location, used at signup?
  field :city, :type => String, :default => ""

  field :description, :type => String, :default => ""
  field :admin, :type => Boolean, :default => false

  field :url, :type => String, :default => ""

  field :thumb_cache_url, :type => String
  field :main_cache_url, :type => String
  field :ios_notification_token, :type => String

  field :highlighted_places, :type => Array, :default => []
  field :blocked_users, :type => Array, :default => []

  # For avatar cropping
  # Initial position of cropping + dimensions
  field :x, :type => Float
  field :y, :type => Float
  field :w, :type => Float
  field :h, :type => Float

  has_many :perspectives, :foreign_key => 'uid', :dependent => :destroy
  has_many :places #ones they created
  has_many :authentications, :dependent => :destroy

  mount_uploader :avatar, AvatarUploader, mount_on: :avatar_filename

  has_and_belongs_to_many :following, class_name: 'User', inverse_of: :followers, autosave: true
  has_and_belongs_to_many :followers, class_name: 'User', inverse_of: :following

  validates_presence_of :username
  validates_presence_of :email
  validates_format_of :username, :with => /\A[a-zA-Z0-9_]+\Z/, :message => "may only contain letters, numbers and underscores"
  validates_format_of :email, :with => /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/, :message => "is not valid"
  validates_length_of :username, :within => 3..20, :too_long => "must be shorter", :too_short => "must be longer"
  validates_uniqueness_of :username, :case_sensitive => false
  validates_uniqueness_of :email, :case_sensitive => false
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me, :encrypted_password, :admin, :description, :url, :user_setting_attributes, :city

  index :unm
  index :email
  index :pc
  index [[:loc, Mongo::GEO2D]], :min => -180, :max => 180
  index :fp, :background => true
  index :du
  index :ck

  before_destroy :clear_user

  #before_validation :fix_location
  after_validation :set_downcase_username
  # For updating avatar see http://railscasts.com/episodes/182-cropping-images
  after_update :process_avatar, :if => :cropping?
  after_create :follow_defaults, :attach_subdocs

  def cropping?
    !x.blank? && !y.blank? && !w.blank? && !h.blank?
  end

  def process_avatar
    self.avatar.recreate_versions!
    self.x = nil
    self.y = nil
    self.w = nil
    self.h = nil
    self.save
  end

  def follow_defaults
    other = User.find_by_username('citysnapshots')
    if other
      self.follow other
    end
  end

  def set_downcase_username
    self.downcase_username = self.username.downcase
  end

  def clear_user
    replacement_user = User.find_by_username("tyler")

    Perspective.any_of({'placemark_comments.user_id' => self.id}).each do |perspective|
      perspective.placemark_comments.destroy_all(:user_id => self.id)
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

  # Fix for users with 0.0, 0.0 or nil as lat/lng
  # TO ADD: better treatment for users with no locations near where they signed up
  def home_location
    location = [49.28, -123.12] # Default value; downtown Vancouver

    # Use case 1: (0.0, 0.0) as lat/lng
    # Use case 2: nil as lat/lng    
    if self.loc == [0.0, 0.0] || self.loc.nil?
      most_recent = Perspective.where(:uid => self.id).order_by([:created_at, :desc]).first
      if most_recent
        location = most_recent.ploc
      end
    else
      location = self.loc
    end

    return location
  end


  def avatar=(obj)
    super(obj)
    # Put your callbacks here, e.g.
    self.creation_environment = nil
    self.main_cache_url = nil
    self.thumb_cache_url = nil
  end

  def cache_urls
    self.creation_environment = Rails.env
    self.thumb_cache_url = self.avatar_url(:thumb)
    self.main_cache_url = self.avatar_url(:main)
    self.save
  end

  def thumb_url
    if Rails.env == self.creation_environment
      self.avatar_url(:thumb)
    elsif thumb_cache_url
      thumb_cache_url
    else
      self.cache_urls
      self.avatar_url(:thumb)
    end
  end

  def main_url
    if Rails.env == self.creation_environment
      self.avatar_url(:main)
    elsif main_cache_url
      main_cache_url
    else
      self.cache_urls
      self.avatar_url(:main)
    end
  end

  def self.ian
    self.where(:du => "imack").first
  end


  def self.lindsay
    self.where(:du => "lindsayrgwatt").first
  end

  def self.top_users(top_n)
    self.desc(:pc).limit(top_n)
  end

  def self.top_nearby(lat, lng, top_n, strict=false)
    # Strict requires that user has either a profile picture or a description and non-empty perspectives

    # Find users with most non-empty perspectives nearby
    nearby_counts = Perspective.collection.group(
        :cond => {:ploc => {'$within' => {'$center' => [[lat, lng], 0.3]}}, :deleted_at => {'$exists' => false}, :empty => false},
        :key => 'uid',
        :initial => {count: 0},
        :reduce => "function(obj,prev) {prev.count++}"
    )

    nearby_counts.sort! { |x, y| y["count"] <=> x["count"] }

    if nearby_counts.length > top_n
      nearby_counts = nearby_counts[0, top_n]
    end

    nearby = []

    nearby_counts.each do |person|
      member = User.find(person["uid"])
      if strict == true
        if member.described? && member.pc > 5 # Arbitrary cut-off of 5 perspectives
          nearby << member
        end
      else
        nearby << member
      end
    end

    # If too short, see if there are nearby users with empty perspectives
    if strict == false && nearby.length < top_n
      nearby_counts = Perspective.collection.group(
          :cond => {:ploc => {'$within' => {'$center' => [[lat, lng], 0.3]}}, :deleted_at => {'$exists' => false}},
          :key => 'uid',
          :initial => {count: 0},
          :reduce => "function(obj,prev) {prev.count++}"
      )

      nearby_counts.sort! { |x, y| y["count"] <=> x["count"] }

      if nearby_counts.length > 2*top_n
        nearby_counts = nearby_counts[0, 2*top_n]
      end

      nearby_counts.each do |person|
        member = User.find(person["uid"])
        if !nearby.include?(member)
          nearby << member
          if nearby.length >= top_n
            break
          end
        end
      end

      if nearby.length > top_n
        nearby = nearby[0, top_n]
      end
    end

    # If still too short, see if there are users based nearby
    if strict == false && nearby.length < top_n
      candidates = User.where(:loc.within => {"$center" => [[lat, lng], 0.3]}).desc(:pc).limit(2*top_n).entries

      candidates.each do |candidate|
        if !nearby.include?(candidate)
          nearby << candidate
          if nearby.length >= top_n
            break
          end
        end
      end
    end

    return nearby
  end

  def self.find_by_username(username)
    self.where(:du => username.downcase).first
  end

  def self.search_by_username(username)
    self.where(:du => /^#{username.downcase}/i).limit(20)
  end

  def self.find_by_crypto_key(key)
    self.where(:ck => key).first
  end

  def perspective_for_place(place)
    place.perspectives.where(:uid => self.id).first
  end

  def following_perspectives_for_place(place)
    place.perspectives.where(:uid.in => self.following_ids).includes(:user).entries
  end

  def is_admin?
    self.admin
  end

  def to_param
    #when routing, this makes the :id really the username
    self.username
  end

  def star(perspective)

    place = perspective.place
    user_perspective = self.perspective_for_place(place)

    if self.id == perspective.user.id
      #shouldn't be able to like own perspective
      return user_perspective
    end

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

  def unstar(perspective)

    place = perspective.place
    user_perspective = self.perspective_for_place(place)

    return unless !user_perspective.nil? #if deleted, its kind of a pointless endeavor

    user_perspective.favourite_perspective_ids.delete(perspective.id)
    user_perspective.save

    perspective.starring_users.delete(self.id)
    perspective.save
  end

  def follows?(user)
    following.include?(user)
  end

  def follow(user)
    if self.id != user.id && !self.following.include?(user)
      self.following << user
    end
  end

  def unfollow(user)
    self.following.to_a #hack to ensure in memory, not a problem for mongodb 2.0  https://github.com/mongoid/mongoid/issues/1369
    self.following.delete(user)
  end

  def user_settings

    if self.user_setting
      return self.user_setting
    else
      self.user_setting = UserSetting.new
      return self.user_setting
    end
  end

  def crypto_key
    if self.ck.nil?
      self.ck = SecureRandom.hex(30)
      self.save!
      return self.ck
    else
      return self.ck
    end
  end

  def described?
    if self.description && self.description != ""
      return true
    elsif self.thumb_cache_url
      return true
    else
      return false
    end
  end

  def has_location?
    if !self.loc || self.loc.nil? || self.loc.length != 2
      return false
    else
      if self.loc == [0.0, 0.0]
        return false
      else
        return true
      end
    end
  end

  def apply_omniauth(omniauth)
    self.email = omniauth['info']['email'] if email.blank?

    if username.blank?
      if omniauth['provider'] == "facebook" && omniauth['info']['nickname']
        username = omniauth['info']['nickname'].gsub(/\W+/, "")[0..18]
      else
        username = omniauth['info']['name'].gsub(/\W+/, "")[0..18]
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

  def comment_notification?
    !ios_notification_token.nil? && self.user_settings.comment_notify
  end

  def follow_notification?
    !ios_notification_token.nil? && self.user_settings.new_follower_notify
  end

  def facebook_friend_notification?
    !ios_notification_token.nil? && self.user_settings.facebook_friend_notify
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

  def highlighted?(place)
    self.highlighted_places.include?(place.id)
  end

  def blocked?(user)
    self.blocked_users.include?(user.id)
  end

  def facebook
    @facebook ||= self.koala_facebook
  end

  def twitter
    for auth in self.authentications
      if auth.provider == 'twitter'
        twitter_auth = auth
      end
    end

    return nil unless !twitter_auth.nil?

    @twitter = Twitter::Client.new(
        :oauth_token => twitter_auth.token,
        :oauth_token_secret => twitter_auth.secret
    )
  end

  def tweet(text, lat=nil, lng=nil)

    for auth in self.authentications
      if auth.provider == 'twitter'
        twitter_auth = auth
      end
    end

    return nil unless !twitter_auth.nil?

    # Exchange our oauth_token and oauth_token secret for the AccessToken instance.
    @access_token = prepare_access_token(twitter_auth.token, twitter_auth.secret)

    if lat && lng
      @response = @access_token.request(:post, "https://api.twitter.com/1/statuses/update.json", :status => text, :lat => lat.to_s, :long => lng.to_s)
    else
      @response = @access_token.request(:post, "https://api.twitter.com/1/statuses/update.json", :status => text)
    end
  end


  def post_facebook?
    #determines whether user has permissions to post to facebook ie. publish_actions
    self.facebook
  end

  # get latest feed using reverse range lookup of sorted set
  # then decode raw JSON back into Ruby objects
  def feed(start =0, count=FEED_COUNT)
    results=$redis.zrevrange key(:feed), start, start + count
    if results.size > 0
      results.collect { |r| Activity.decode(r) }
    else
      []
    end
  end

  def notifications(start =0, count=100)
    results=$redis.zrevrange key(:notifications), start, start + count
    if results.size > 0
      results.collect { |r| Notification.decode(r) }
    else
      []
    end
  end

  def old_feed(start_pos = 0, count=20)
    @activities = []
    for user in self.following
      if user.activity_feed
        head = user.activity_feed.head_chunk
        @activities = @activities + head.activities
        if !head.next.nil?
          @activities = @activities + head.next.activities
        end
      end
    end

    if self.activity_feed
      @activities = @activities + self.activity_feed.activities
    end

    @activities.sort! { |a, b| a.created_at <=> b.created_at }
    @activities.reverse!
    @activities = @activities[start_pos, count]
  end

  # get older statuses by using reverse range by score lookup
  def ofeed(max, obj=true, id=self.id_s, limit=FEED_COUNT, scores=false)
    results=$redis.zrevrangebyscore(key(:feed), "(#{max}", "-inf", :limit => [0, limit], :with_scores => scores)
    if obj && results.size > 0
      results.collect { |r| Activity.decode(r) }
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
    if ($redis.zcard k) >= indx
      n = indx - 1
      if (r = $redis.zrevrange k, n, n, :with_scores => true)
        $redis.zremrangebyscore k, "-inf", "(#{r.last}"
      end
    end
  end

  def og_path
    "https://#{ActionMailer::Base.default_url_options[:host]}#{Rails.application.routes.url_helpers.user_path(self)}"
  end

  def facebook_profile_id
    if self.third_party_id.nil?
      if self.facebook
        begin
          result = self.facebook.get_object("me", :fields => "third_party_id")
          self.third_party_id = result['third_party_id']
          self.save
          return self.third_party_id
        rescue
          return nil
        end
      else
        return nil
      end
    else
      return third_party_id
    end
  end

  def as_json(options={})
    #these could eventually be paginated #person.posts.paginate(page: 2, per_page: 20)
    attributes = {:id => self['_id'],
                  :username => self['username'],
                  :picture => {
                      :id => self['_id'],
                      :thumb_url => thumb_url,
                      :main_url => main_url},
                  :perspectives_count => self['pc'],
                  :url => self.url,
                  :description => self.description,
                  :main_url => main_url,
                  :city => self.city,
                  :follower_count => followers.count,
                  :following_count => following.count,
                  :fullname => self['fullname'],
                  :location => self.location
    }

    attributes = attributes.merge(:lat => self.location[0], :lng => self.location[1]) unless self.location.nil?

    if options[:current_user]
      current_user =options[:current_user]
      #check against raw ids so it doesnt have to go back to db
      following = self['follower_ids'].include?(options[:current_user].id) ||self.id == options[:current_user].id
      follows_you = self['following_ids'].include?(options[:current_user].id)
      attributes[:blocked] = current_user.blocked?(self)

      attributes = attributes.merge(:following => following, :follows_you => follows_you)
      if self.id == current_user.id
        attributes = attributes.merge(:auths => self.authentications)
        attributes = attributes.merge(:notification_count => self.notification_count)
        attributes = attributes.merge(:highlighted_count => self.highlighted_places.count)
      end
    else
      current_user = nil
    end

    if (options[:perspectives] == :location)
      attributes.merge(:perspectives => self.perspectives.near(:loc => options[:location]).includes(:place).as_json({:user_view => true, :current_user => current_user}))
    elsif (options[:perspectives] == :created_by)
      attributes.merge(:perspectives => self.perspectives.descending(:modified_at).includes(:place).limit(10).as_json({:user_view => true, :current_user => current_user}))
    else
      attributes
    end
  end


  protected

  def self.find_for_database_authentication(conditions)
    login = conditions.delete(:login)
    self.any_of({:du => login.downcase}, {:email => login}).first
  end

  def koala_facebook
    for auth in self.authentications
      if auth.provider == 'facebook' && !auth.token.nil?
        return Koala::Facebook::API.new(auth.token)
      end
    end
    return nil
  end

  def prepare_access_token(oauth_token, oauth_token_secret)
    consumer = OAuth::Consumer.new(CHATHAM_CONFIG['twitter_consumer_key'], CHATHAM_CONFIG['twitter_secret_key'],
                                   {
                                       :site => "https://api.twitter.com"
                                   })
    # now create the access token object from passed values
    token_hash =
        {
            :oauth_token => oauth_token,
            :oauth_token_secret => oauth_token_secret
        }
    access_token = OAuth::AccessToken.from_hash(consumer, token_hash)
    return access_token
  end

end
