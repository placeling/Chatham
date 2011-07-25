class User
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable


  field :username,      :type =>String
  field :perspective_count,  :type=>Integer, :default => 0 #property for easier lookup of of top users

  has_many :perspectives
  has_many :places #ones they created
  has_many :client_applications
  has_many :tokens, :class_name=>"OauthToken",:order=>"authorized_at desc",:include=>[:client_application]

  validates_presence_of :username
  validates_uniqueness_of :username, :email, :case_sensitive => false
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me

  index :username
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


  def as_json(options={})

    #these could eventually be paginated #person.posts.paginate(page: 2, per_page: 20)
    if (options[:perspectives] == :location)
      attributes.merge(:perspectives => self.perspectives.near(:location => options[:location] ) )
    elsif (options[:perspectives] == :created_by )
      attributes.merge(:perspectives => self.perspectives.descending(:created_at))
    else
      attributes
    end
  end

end
