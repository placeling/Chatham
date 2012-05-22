class WelcomeEmail
  @queue = :email_queue
  
  def self.perform(user_id)
    user = User.find( user_id )
    
    Notifier.welcome(user).deliver
  end
end