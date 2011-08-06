class User
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable


  field :username,      :type =>String
  alias :login :username
  field :email,         :type =>String
  field :perspective_count,  :type=>Integer, :default => 0 #property for easier lookup of of top users

  has_many :perspectives
  has_many :places #ones they created

  has_and_belongs_to_many :followers, :class_name =>"User", :inverse_of => nil
  has_and_belongs_to_many :followees, :class_name =>"User", :inverse_of => nil

  has_many :client_applications
  has_many :tokens, :class_name=>"OauthToken",:order=>"authorized_at desc",:include=>[:client_application]

  validates_presence_of :username
  validates_uniqueness_of :username, :email, :case_sensitive => false
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me

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
    return false
  end

  def to_param
    #when routing, this makes the :id really the username
    self.username
  end

  def follow( other_user )
    other_user.followers << self
    self.followees << other_user
  end

  def unfollow( other_user )
    other_user.followers.delete self
    self.followees.delete other_user
  end


  def as_json(options={})
    #these could eventually be paginated #person.posts.paginate(page: 2, per_page: 20)
    attributes = self.attributes.slice('username', 'perspective_count')
    if (options[:perspectives] == :location)
      attributes.merge(:perspectives => self.perspectives.near(:location => options[:location] ) )
    elsif (options[:perspectives] == :created_by )
      attributes.merge(:perspectives => self.perspectives.descending(:created_at))
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
