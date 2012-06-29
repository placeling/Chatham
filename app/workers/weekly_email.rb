class WeeklyEmail
  @queue = :email

  def self.perform()

    if Rails.env.production?
      User.all.limit(20).each do |user|
        if user.weekly_email? && !user.loc.nil?
          Notifier.weekly(user).deliver
        end
      end
    else
      user = User.find_by_username("imack")
      Notifier.weekly(user).deliver
    end

  end
end