class Publisher
  include Mongoid::Document
  field :domain, :type => String, :default => ""
  field :google_analytics_code, :type => String, :default => ""

  field :home_liquid_template, :type => String, :default => File.read("#{::Rails.root.to_s}/config/templates/home.liquid")
  field :css_liquid_template, :type => String, :default => File.read("#{::Rails.root.to_s}/config/templates/css.liquid")

  has_and_belongs_to_many :permitted_users, class_name: 'User', inverse_of: nil, autosave: true

  accepts_nested_attributes_for :publisher_category, allow_destroy: true
  embeds_many :publisher_categories

  belongs_to :user

  validates_presence_of :user
  validates_format_of :domain, :with => URI::regexp(%w(httdp)), :allow_nil => true, :allow_blank => true
  validates_format_of :google_analytics_code, :with => /\Aua-\d{4,9}-\d{1,4}$\Z/i, :allow_nil => true, :allow_blank => true

  liquid_methods :publisher_categories

  after_save :invalidate_cache

  def self.forgiving_find(publisher_id)
    if BSON::ObjectId.legal?(publisher_id)
      publisher = Publisher.find(publisher_id)
    else
      user = User.find_by_username(publisher_id)
      publisher = user.publisher
    end
    return publisher
  end


  def self.available_for(current_user)
    return Publisher.all unless !current_user.is_admin?
    Publisher.any_of({'permitted_user_ids' => current_user.id}, {:user_id => current_user.id})
  end

  def category_for(category)
    return self.publisher_categories.where(:slug => category).first
  end

  def invalidate_cache
    $redis.publish "invalidations", {'model' => "publisher", "id" => self.id, "publisher" => self}.to_json
  end

  def as_json(options={})
    self.attributes.merge(:publisher_categories => self.publisher_categories.as_json(options))
  end

end
