class WeeklyEmail
  @queue = :email_queue

  def self.perform()

    if Rails.env.production?
      User.all.each do |user|
        if user.weekly_email? && !user.loc.nil? && user.loc != [0.0, 0.0]
          mail = Notifier.weekly(user.id)
          mail.deliver unless mail.to == nil || mail.from == nil
        end
      end
    else
      User.all.limit(20).each do |user|
        if user.weekly_email? && !user.loc.nil? && user.loc != [0.0, 0.0]
          mail = Notifier.weekly(user.id)
          #mail.deliver unless mail.to == nil don't actually deliver by default
        elsif user.weekly_email?
          puts "skip #{user.username} because loc= #{user.loc}"
        end
      end
    end

  end
end