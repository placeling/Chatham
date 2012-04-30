class SendNotifications
  @queue = :apns_queue
  def self.perform( user_id, message, url = nil)
    user = User.find( user_id )

    if url
      n = [user.ios_notification_token, :aps=>{:alert=>message, :sound => 'default'}, :url => url]
    else
      n = [user.ios_notification_token, :aps=>{:alert=>message, :sound => 'default'}]
    end

    APNS.send_notifications( [n] )
  end
end