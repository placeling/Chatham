class WeeklyEmail
  @queue = :email_queue

  def self.perform()

    if Rails.env.production?
      User.all.each do |user|
        if user.weekly_email? && !user.loc.nil?
          mail = Notifier.weekly(user.id)
          mail.deliver unless mail.to == nil
        end
      end
    else
      User.all.limit(20).each do |user|
        if user.weekly_email? && !user.loc.nil?
          mail = Notifier.weekly(user.id)
          #mail.deliver unless mail.to == nil don't actually deliver by default
        end
      end
    end

  end
end