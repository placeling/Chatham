class NewFacebookUser
    @queue = :facebook_queue
    def self.perform(user_id)
      user = User.find( user_id )

      me = user.facebook.fetch
      friends = user.facebook.friends
      begin
        friends.each do |friend|
          if auth = Authentication.find_by_provider_and_uid("facebook", friend.identifier)

            auth.user.fullname = friend.name
            $redis.sadd("facebook_friends_#{user.id}" , [auth.user.id, friend.identifier, friend.name].to_json )

            if $redis.smembers("facebook_friends_#{auth.user.id}").count > 0 #only do it for other user if already initialized
              $redis.sadd("facebook_friends_#{auth.user.id}" , [user.id, me.identifier, me.name].to_json )
            end
          end
        end
        friends = friends.next
      end while friends.count > 0
    end
end