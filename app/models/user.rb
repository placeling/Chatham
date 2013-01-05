require 'cityname_finder'
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
  has_many :questions
  has_one :publisher

  mount_uploader :avatar, AvatarUploader, mount_on: :avatar_filename

  has_and_belongs_to_many :following, class_name: 'User', inverse_of: :followers, autosave: true
  has_and_belongs_to_many :followers, class_name: 'User', inverse_of: :following

  has_many :client_applications, :foreign_key => 'uid'
  has_many :tokens, :class_name => "OauthToken", :order => "authorized_at desc", :foreign_key => 'uid', :dependent => :delete

  embeds_one :activity_feed
  embeds_one :user_setting
  embeds_one :user_tour
  embeds_one :user_recommendation
  embeds_one :first_run
  accepts_nested_attributes_for :user_setting
  accepts_nested_attributes_for :user_tour

  validate :acceptable_name, :on => :create
  validate :acceptable_password
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

  before_save :get_city
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

  def get_city
    if self.location != nil && self.location != [0, 0] && self.city == ""
      self.city = CitynameFinder.getCity(self.location[0], self.location[1])
    end
  end

  def attach_subdocs
    if !self.activity_feed
      self.create_activity_feed
    end

    if !self.user_setting
      self.create_user_setting
    end

    if !self.first_run
      self.create_first_run
    end

    if !self.user_recommendation
      self.create_user_recommendation
    end

    if !self.user_tour
      self.create_user_tour
    end

    track! :signup

  end

  def attach_first_run
    if !self.first_run
      self.create_first_run
    end
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

  def clear_user
    replacement_user = User.find_by_username("tyler")

    Perspective.any_of({'placemark_comments.user_id' => self.id}).each do |perspective|
      perspective.placemark_comments.destroy_all(:user_id => self.id)
    end

    self.questions.each do |question|
      question.user = replacement_user
      question.save!
    end

    Question.any_of({'answers.answer_comments.user_id' => self.id}).each do |question|
      question.answers.any_of({'answer_comments.user_id' => self.id}).each do |answer|
        answer.answer_comments.destroy_all(:user_id => self.id)
      end
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

  def remove_tokens_for(client_application)
    self.tokens.where(:cid => client_application.id).delete_all
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

  def crypto_key
    if self.ck.nil?
      self.ck = SecureRandom.hex(30)
      self.save!
      return self.ck
    else
      return self.ck
    end
  end

  def week_in_review
    scored = {}
    guides = []

    weekago = Time.now - (24*60*60*7)

    # User's activity that week
    activity = {}

    last_week = Perspective.where(:uid => self.id, :created_at => {'$gte' => weekago})

    activity['count'] = last_week.length
    activity['photos'] = []

    last_week.each do |perp|
      perp.pictures.each do |pic|
        activity['photos'] << {'perp' => perp, 'pic' => pic}
      end
    end

    # Activity by guides the user follows
    self.following.each do |following|
      # Guides
      actions = ActivityFeedChunk.where("activities.user1" => following.id, "activities.created_at" => {'$gte' => weekago}, "activities.activity_type" => "FOLLOW")

      actions.each do |chunk|
        chunk.activities.each do |activity|
          if activity.activity_type == "FOLLOW"
            actor = User.find_by_username(activity.username2)
            if !self.following.include?(actor) && actor != self
              if !guides.include?(actor)
                guides << actor
              end
            end
          end
        end
      end

      if guides.length > 0
        guides.sort! { |a, b| a.followers.length <=> b.followers.length }
        guides.reverse!
      end

      #Places
      recent = Perspective.where(:uid => following.id, :created_at => {"$gte" => weekago})
      if recent.length > 0
        recent.each do |perp|
          if (perp.memo && perp.memo.length >0) || perp.pictures.length > 0
            temp = {}
            temp["perp"] = perp

            score = 0

            if !following.thumb_cache_url.nil?
              score += 2 # 2 points for a profile picture
            end

            if perp.pictures.length > 0
              temp["pictures"] = true
              score += 2 # 2 points for at least one photo
            else
              temp["pictures"] = false
            end

            if perp.memo && perp.memo.length > 0
              temp["memo"] = true
              score += 1 # 1 point for a memo
            else
              temp["memo"] = false
            end

            my_perspective = Perspective.where(:uid => self.id, :plid => perp.place.id)
            if my_perspective.length > 0
              temp["mine"] = true
              if score > 0
                score = 1 # Low score for places already on my map
              end
            else
              temp["mine"] = false
            end

            temp["score"] = score

            scored[perp] = score
          end
        end
      end
    end

    # Questions
    q = Question.where(:user_id => {'$in' => self.following_ids}, :created_at => {"$gte" => weekago})

    return scored, guides, activity, q
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

  def get_recommendations
    if self.has_location?
      previous = self.user_recommendation.recommended_ids

      # Question
      questions = Question.nearby_questions(self.loc[0], self.loc[1]).shuffle # Want randomly organized

      clean_questions = []

      questions.each do |question|
        if question.user != self && !previous.include?(question.id)
          clean_questions << question
        end
      end

      questions = clean_questions[0, 1]

      questions.each do |question|
        self.user_recommendation.recommended_ids << question.id
      end

      # Guide
      candidates = User.top_nearby(self.loc[0], self.loc[1], 100, true)

      clean_candidates = []

      candidates.each do |candidate|
        if !self.following_ids.include?(candidate.id) && !previous.include?(candidate.id)
          clean_candidates << candidate
        end
      end

      if clean_candidates.include?(self)
        clean_candidates.delete(self)
      end

      city_snapshots = User.find_by_username('citysnapshots')
      if clean_candidates.include?(city_snapshots)
        clean_candidates.delete(city_snapshots)
      end

      tyler = User.find_by_username('tyler')
      if clean_candidates.include?(tyler)
        clean_candidates.delete(tyler)
      end

      candidates = clean_candidates[0, 1]

      candidates.each do |candidate|
        self.user_recommendation.recommended_ids << candidate.id
      end

      # Place
      # Technically return a perspective because we want to show a testimonial
      candidate_places = Place.top_nearby_places(self.loc[0], self.loc[1], 0.3, 100).entries

      my_places = []
      self.perspectives.each do |perspective|
        my_places << perspective.place
      end

      clean_places = []

      candidate_places.each do |place|
        if !my_places.include?(place) && !previous.include?(place.id) && !place.venue_types.include?("Political")
          clean_places << place
        end
      end

      growlab = Place.where('name' => 'Growlab').first()
      if clean_places.include?(growlab)
        clean_places.delete(growlab)
      end

      # Convert places to high quality perspectives
      candidate_place_to_perspectives = []
      clean_places.each do |place|
        place.perspectives.each do |perp|
          if perp.high_value?
            candidate_place_to_perspectives << perp
          end
        end
      end

      candidate_place_to_perspectives.shuffle! # Randomize so don't always get 1st perspective on a place

      places = candidate_place_to_perspectives[0, 1]

      places.each do |place|
        self.user_recommendation.recommended_ids << place.place.id
      end

      # Tours
      tours = []
      candidate_tours = Tour.top_nearby(self.loc[0], self.loc[1], 0.3).entries

      clean_tours = []

      candidate_tours.each do |tour|
        if !self.user_tour.subscribed_tour_ids.include?(tour.id) && !previous.include?(tour.id) && tour.user != self
          clean_tours << tour
        end
      end

      tours = candidate_tours[0, 1]

      tours.each do |tour|
        self.user_recommendation.recommended_ids << tour.id
      end

      self.save

      if candidates.length > 0 || questions.length > 0 || places.length >0 || tours.length > 0
        return {"guides" => candidates, "questions" => questions, "places" => places, "tours" => tours}
      else
        return nil
      end
    else
      return nil
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

  def suggestion_notification?
    !ios_notification_token.nil? && self.user_settings.suggested_place_notify
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

  def question_email?
    self.confirmed? && self.user_settings.question_updates_email
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
    if self.publisher
      attributes = attributes.merge(:publisher_id => self.publisher.id)
    end

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
