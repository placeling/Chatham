class FacebookPost
  @queue = :facebook_queue

  def self.perform(actor_id, action_name, args_dict)

    actor1 = User.find(actor_id)

    begin
      actor1.facebook.put_connections("me", action_name, args_dict)
    rescue Koala::Facebook::APIError => exc
      if exc.fb_error_code == 190
        fb_auth = actor1.authentications.where(:p => "facebook").first
        fb_auth.expiry = 1.day.ago #no longer valid, so cancel out
        fb_auth.save
      elsif exc.fb_error_code == 200
        RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{actor1.username} doesn't authorize publish actions for facebook"
      else
        raise exc
      end
    end
  end
end