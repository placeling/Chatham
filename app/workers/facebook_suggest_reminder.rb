class FacebookSuggestReminder
  #sent a day later to remind person to check facebook
  @queue = :facebook_queue

  def self.perform(user_id)
    user = User.find(user_id)

    if user.facebook && user.ios_notification_token #&& !user.user_settings.facebook_friend_check
      #only send if we have facebook, an ios_notification token, and hasn't done the friend check

      friends_json = $redis.smembers("facebook_friends_#{user.id}")
      tally = friends_json.count

      if tally > 2
        RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{user.username} notified of  #{tally-1} facebook friends on placeling"
        Resque.enqueue(SendNotifications, user_id, "You have #{tally-1} Facebook friends on Placeling, check them out!", "placeling://facebookfriends")
      end
    end

  end

end
