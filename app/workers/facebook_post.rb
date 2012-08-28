class FacebookPost
  @queue = :facebook_queue

  def self.perform(actor_id, action_name, args_dict)

    actor1 = User.find(actor_id)

    begin
      actor1.facebook.put_connections("me", action_name, args_dict)
    rescue Koala::Facebook::APIError => exc
      if exc.fb_error_type == 190
        fb_auth = actor1.authentications.where(:p => "facebook").first
        fb_auth.expiry = 1.day.ago #no longer valid, so cancel out
        fb_auth.save
        raise "Facebook Error 190 for #{actor1.username}, reset expiry of token"
      else
        raise exc
      end
    end
  end
end