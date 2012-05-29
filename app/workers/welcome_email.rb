class WelcomeEmail
  @queue = :apns_queue
  
  def self.perform(user_id)
    user = User.find( user_id )
    Rails.logger.debug "Sending welcome email to #{user.username}"
    Notifier.welcome(user).deliver
  end
end