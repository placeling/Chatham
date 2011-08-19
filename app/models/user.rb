class User
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable


  field :username,      :type =>String
  field :fullname,      :type =>String
  alias :login :username
  field :email,         :type =>String
  field :perspective_count,  :type=>Integer, :default => 0 #property for easier lookup of of top users

  field :location, :type => Array #meant to be home location, used at signup?
  index [[ :location, Mongo::GEO2D ]], :min => -180, :max => 180

  field :description, :type => String
  field :admin,       :type => Boolean, :default => false

  has_many :perspectives
  has_many :places #ones they created

  has_and_belongs_to_many :followers, :class_name =>"User", :inverse_of => nil
  has_and_belongs_to_many :following, :class_name =>"User", :inverse_of => nil

  has_many :client_applications
  has_many :tokens, :class_name=>"OauthToken",:order=>"authorized_at desc",:include=>[:client_application]

  validates_presence_of :username
  validates_uniqueness_of :username, :email, :case_sensitive => false
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me, :admin

  index :username
  index :email
  index :perspective_count


  def self.top_users( top_n )
    self.desc( :perspective_count ).limit( top_n )
  end

  def self.find_by_username( username )
    self.where( :username => username ).first
  end

  def is_admin?
    self.admin
  end

  def to_param
    #when routing, this makes the :id really the username
    self.username
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
    attributes = self.attributes.slice('username', 'perspective_count')
    attributes = attributes.merge(:follower_count => followers.count, :following_count => following.count)

    if options[:current_user]
      #check against raw ids so it doesnt have to go back to db
      following = self['follower_ids'].include?( options[:current_user].id )
      follows_you = self['following_ids'].include?( options[:current_user].id )
      attributes = attributes.merge(:following => following, :follows_you => follows_you)
    end

    if (options[:perspectives] == :location)
      attributes.merge(:perspectives => self.perspectives.near(:location => options[:location] ) )
    elsif (options[:perspectives] == :created_by )
      attributes.merge(:perspectives => self.perspectives.descending(:created_at) )
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
