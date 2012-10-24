class TwitterPost
  @queue = :twitter_queue

  def self.perform(actor_id, tweet_status, lat = nil, lng = nil)

    actor1 = User.find(actor_id)


    actor1.tweet(tweet_status, lat, lng)

  end
end
