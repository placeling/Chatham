class TwitterPost
  @queue = :twitter_queue

  def self.perform(actor_id, tweet_status, lat = nil, lng = nil)

    actor1 = User.find(actor_id)


    resp = actor1.tweet(tweet_status, lat, lng)

    if resp.code != 200
      raise "#{actor1.username} can't post twitter, #{r.code}, #{r.message}"
    end
  end
end
