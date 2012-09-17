class DestroyUser
  @queue = :admin

  def self.perform(user_id)

    user = User.find(user_id)
    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - Destroying user #{user.username}, #{user.id}"
    user.destroy

  end
end