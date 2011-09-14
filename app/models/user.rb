class User
  include Mongoid::Document
  include Mongoid::Paranoia
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable


  field :username,      :type =>String
  field :fullname,      :type =>String
  alias :login :username
  field :email,         :type =>String
  field :pc, :as => :perspective_count,  :type=>Integer, :default => 0 #property for easier lookup of of top users

  field :fp, :as => :favourite_perspectives,    :type => Array, :default =>[]

  field :loc, :as => :location, :type => Array #meant to be home location, used at signup?

  field :description, :type => String
  field :admin,       :type => Boolean, :default => false

  field :facebook_access_token, :type => String

  has_many :perspectives, :foreign_key => 'uid'
  has_many :places #ones they created

  has_and_belongs_to_many :followers, :class_name =>"User", :inverse_of => nil
  has_and_belongs_to_many :following, :class_name =>"User", :inverse_of => nil

  has_many :client_applications, :foreign_key =>'uid'
  has_many :tokens, :class_name=>"OauthToken",:order=>"authorized_at desc",:include=>[:client_application], :foreign_key =>'uid'

  validates_presence_of :username
  validates_uniqueness_of :username, :email, :case_sensitive => false
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me, :admin, :description, :facebook_access_token

  index :unm
  index :email
  index :pc
  index [[ :loc, Mongo::GEO2D ]], :min => -180, :max => 180
  index :fp, :background => true


  def self.top_users( top_n )
    self.desc( :pc ).limit( top_n )
  end

  def self.find_by_username( username )
    self.where( :username => username ).first
  end

  def remove_tokens_for( client_application )
    self.tokens.where(:cid =>client_application.id).delete_all
  end

  def perspective_for_place( place )
    place.perspectives.where(:uid => self.id).first
  end

  def following_perspectives_for_place( place )
    place.perspectives.where(:uid.in => self.following_ids)
  end

  def is_admin?
    self.admin
  end

  def to_param
    #when routing, this makes the :id really the username
    self.username
  end

  def star( perspective )
    self.favourite_perspectives << perspective.id
    perspective.fav_count += 1

    place = perspective.place
    user_perspective = self.perspective_for_place( place )

    #starring a perspective triggers a bookmark of it
    if user_perspective.nil?
      user_perspective= place.perspectives.build()
      user_perspective.user = self
      user_perspective.save
    end

  end

  def unstar( perspective )
    self.favourite_perspectives.delete( perspective.id )
    perspective.fav_count -= 1
  end

  def follows?( other_user )
    following.include?( other_user )
  end

  def follow( other_user )
    other_user.followers << self
    self.following << other_user
  end

  def unfollow( other_user )
    other_user.followers.delete self
    self.following.delete other_user
  end


  def as_json(options={})
    #these could eventually be paginated #person.posts.paginate(page: 2, per_page: 20)
    attributes = {:username => self['username'], :perspectives_count =>self['pc']}
    attributes = attributes.merge(:follower_count => followers.count, :following_count => following.count)

    if options[:current_user]
      #check against raw ids so it doesnt have to go back to db
      following = self['follower_ids'].include?( options[:current_user].id ) ||self.id == options[:current_user].id
      follows_you = self['following_ids'].include?( options[:current_user].id )
      attributes = attributes.merge(:following => following, :follows_you => follows_you)
    end

    if (options[:perspectives] == :location)
      attributes.merge(:perspectives => self.perspectives.near(:loc => options[:location] ).as_json(:user_view=>true)  )
    elsif (options[:perspectives] == :created_by )
      attributes.merge(:perspectives => self.perspectives.descending(:created_at).as_json(:user_view=>true) )
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
