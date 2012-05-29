class WelcomeEmail
  @queue = :apns_queue
  
  def self.perform(user_id)
    Notifier.welcome(user_id).deliver
  end
end