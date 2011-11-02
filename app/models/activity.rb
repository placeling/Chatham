class Activity
  include Mongoid::Document
  include Mongoid::Timestamps

  field :activity_type, :type => String

  field :user1, :as => :actor1, :type => BSON::ObjectId
  field :username1, :type => String
  field :thumb1, :type => String
  
  field :user2, :as => :actor2, :type => BSON::ObjectId
  field :username2, :type => String

  field :subject, :type => BSON::ObjectId
  field :subject_title, :type => String

  embedded_in :activity_feed_chunk

  validates_presence_of :actor1, :username1


  def as_json(options={})
    #these could eventually be paginated #person.posts.paginate(page: 2, per_page: 20)

    if self.thumb1.nil?
      user = User.find_by_username(self.username1)
      if user && user.thumb_url
        self.thumb1 = user.thumb_url
      end
    else
      puts self.thumb1
    end

    self.attributes
  end

end