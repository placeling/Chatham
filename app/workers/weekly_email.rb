class WeeklyEmail
  @queue = :email

  def self.perform()

    if Rails.env.production?
      User.all.each do |user|
        if user.weekly_email? && !user.loc.nil?
          Notifier.weekly(user).deliver
        end
      end
    else
      User.all.limit(20).each do |user|
        if user.weekly_email? && !user.loc.nil?
          Notifier.weekly(user).deliver
        end
      end
    end

  end
end