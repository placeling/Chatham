class Publisher
  include Mongoid::Document
  field :css, :type => String, :default => ""
  field :liquid, :type => String
  field :domain, :type => String, :default => ""
  field :google_analytics_code, :type => String, :default => ""

  has_and_belongs_to_many :permitted_users, class_name: 'User', inverse_of: nil, autosave: true

  accepts_nested_attributes_for :publisher_category, allow_destroy: true
  embeds_many :publisher_categories

  belongs_to :user

  validates_presence_of :user
  validates_format_of :domain, :with => URI::regexp(%w(httdp)), :allow_nil => true, :allow_blank => true
  validates_format_of :google_analytics_code, :with => /\Aua-\d{4,9}-\d{1,4}$\Z/i, :allow_nil => true, :allow_blank => true

  after_save :invalidate_cache

  def self.available_for(current_user)
    return Publisher.all unless !current_user.is_admin?
    Publisher.any_of({'permitted_user_ids' => current_user.id}, {:user_id => current_user.id})
  end

  def category_for(category)
    return self.publisher_categories.where(:slug => category).first
  end

  def invalidate_cache
    $redis.publish "invalidations", {'model' => "publisher", "id" => self.id}.to_json
  end

  def as_json(options={})
    self.attributes.merge(:publisher_categories => self.publisher_categories.as_json(options))
  end

end
