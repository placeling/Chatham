class WeeklyEmail
  @queue = :email_queue

  def self.perform()

    if Rails.env.production?
      User.all.each do |user|
        if user.weekly_email? && !user.loc.nil?
          Notifier.weekly(user.id).deliver
        end
      end
    else
      User.all.limit(20).each do |user|
        if user.weekly_email? && !user.loc.nil?
          mail = Notifier.weekly(user.id)
          mail.deliver unless mail.to == nil
        end
      end
    end

  end
end