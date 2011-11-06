class User
  include Mongoid::Document
  include Mongoid::Paranoia
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  #before_validation :fix_location
  after_create :cache_urls

  field :username,      :type =>String
  field :fullname,      :type =>String
  alias :login :username
  field :email,         :type =>String
  field :pc, :as => :perspective_count,  :type=>Integer, :default => 0 #property for easier lookup of of top users
  field :fp, :as => :favourite_perspectives,    :type => Array, :default =>[]

  field :loc, :as => :location, :type => Array #meant to be home location, used at signup?

  field :description, :type => String, :default => ""
  field :admin,       :type => Boolean, :default => false

  field :url, :type => String, :default => ""
  field :facebook_access_token, :type => String
  field :facebook_id, :type => Integer

  field :thumb_cache_url, :type => String
  field :main_cache_url, :type => String

  has_many :perspectives, :foreign_key => 'uid'
  has_many :places #ones they created

  field :fbDict, :type => Hash

  mount_uploader :avatar, AvatarUploader

  has_and_belongs_to_many :followers, :class_name =>"User", :inverse_of => nil
  has_and_belongs_to_many :following, :class_name =>"User", :inverse_of => nil

  has_many :client_applications, :foreign_key =>'uid'
  has_many :tokens, :class_name=>"OauthToken",:order=>"authorized_at desc",:include=>[:client_application], :foreign_key =>'uid'

  embeds_one :activity_feed

  validate :acceptable_name, :on => :create
  validate :acceptable_password
  validates_presence_of :username
  validates_format_of :username, :with => /\A[a-zA-Z0-9]+\Z/, :message => "must only contain letters and number"
  validates_length_of :username, :within => 3..20, :too_long => "pick a shorter username", :too_short => "pick a longer username"
  validates_uniqueness_of :username, :email, :case_sensitive => false
  validates_uniqueness_of :facebook_id, :allow_nil =>true
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me, :admin, :description, :facebook_access_token

  index :unm
  index :email
  index :pc
  index [[ :loc, Mongo::GEO2D ]], :min => -180, :max => 180
  index :fp, :background => true
  index :facebook_id

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
    self.thumb_cache_url = self.avatar_url(:thumb)
    self.main_cache_url =  self.avatar_url(:main)
    self.save
  end

  def thumb_url
    if thumb_cache_url
      return thumb_cache_url
    else
      self.thumb_cache_url = self.avatar_url(:thumb)
      return self.avatar_url(:thumb)
    end
  end

  def main_url
    if main_cache_url
      return main_cache_url
    else
      self.thumb_cache_url = self.avatar_url(:main)
      return self.avatar_url(:main)
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
    self.where( :username => username ).first
  end

  def self.find_by_facebook_id( fid )
    self.where( :facebook_id => fid ).first
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
      user_perspective.skip_feed = true
    end

    user_perspective.favourite_perspectives << perspective.id
    user_perspective.save

    perspective.starring_users << self.id
    perspective.save

    ActivityFeed.add_star_perspective(self, perspective.user, perspective)
  end

  def unstar( perspective )

    place = perspective.place
    user_perspective = self.perspective_for_place( place )

    user_perspective.favourite_perspectives.delete( perspective.id )
    user_perspective.save

    perspective.starring_users.delete( self.id )
    perspective.save
  end

  def follows?( other_user )
    following.include?( other_user )
  end

  def follow( other_user )
    other_user.followers << self
    self.following << other_user
    ActivityFeed.add_follow( self, other_user)
  end

  def unfollow( other_user )
    other_user.followers.delete self
    self.following.delete other_user
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


  def as_json(options={})
    #these could eventually be paginated #person.posts.paginate(page: 2, per_page: 20)
    attributes = {:username => self['username'],  :perspectives_count =>self['pc'],
                  :url => self.url, :description => self.description,
                  :thumb_url => thumb_url, :main_url => main_url }

    attributes = attributes.merge(:follower_count => followers.count, :following_count => following.count)

    if options[:current_user]
      current_user =options[:current_user]
      #check against raw ids so it doesnt have to go back to db
      following = self['follower_ids'].include?( options[:current_user].id ) ||self.id == options[:current_user].id
      follows_you = self['following_ids'].include?( options[:current_user].id )
      attributes = attributes.merge(:following => following, :follows_you => follows_you, :email => self.email, :location=>self[:loc])
    else
      current_user = nil
    end

    if (options[:perspectives] == :location)
      attributes.merge(:perspectives => self.perspectives.near(:loc => options[:location] ).as_json({:user_view=>true,:current_user =>current_user })  )
    elsif (options[:perspectives] == :created_by )
      attributes.merge(:perspectives => self.perspectives.descending(:created_at).limit(10).as_json({:user_view=>true,:current_user =>current_user }) )
    else
      attributes
    end
  end

  protected

  def self.find_for_database_authentication(conditions)
    login = conditions.delete(:login)
    self.any_of({ :username => login }, { :email => login }).first
  end

end
