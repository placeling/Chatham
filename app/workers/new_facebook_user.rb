class NewFacebookUser
  @queue = :facebook_queue

  def self.perform(user_id)
    user = User.find(user_id)

    begin
      me = user.facebook.fetch
    rescue Exception => e
      puts "\t\t#{e.message}"
      return
    end

    Resque.enqueue_in(1.day, FacebookSuggestReminder, user_id)

    friends = user.facebook.friends
    begin
      friends.each do |friend|
        if auth = Authentication.find_by_provider_and_uid("facebook", friend.identifier)

          auth.user.fullname = friend.name
          $redis.sadd("facebook_friends_#{user.id}", [auth.user.id, friend.identifier, friend.name].to_json)

          if $redis.smembers("facebook_friends_#{auth.user.id}").count > 0 #only do it for other user if already initialized
            $redis.sadd("facebook_friends_#{auth.user.id}", [user.id, me.identifier, me.name].to_json)
          end

          if auth.user.notifications.count > 0 && auth.user.notifications[0].created_at < 1.day.ago && !auth.user.follows?(user)
            #send the notification if the user hasn't gotten anything in at least a day

            if auth.user.facebook_friend_notification?
              Resque.enqueue(SendNotifications, auth.user.id, "Your facebook friend, #{me.name}, joined Placeling!", "placeling://users/#{user.username}")

              notification = Notification.new(:actor1 => user.id, :actor2 => auth.user.id, :type => "FACEBOOK_FRIEND", :subject_name => user.username, :email => false, :apns => true)
              notification.remember #redis backed
            end
          end
        end
      end
      friends = friends.next
    end while friends.count > 0


  end
end