class WeeklyEmail
  @queue = :email

  def self.perform()

    if Rails.env.production?
      User.all.limit(20).each do |user|
        if user.weekly_email? && !user.loc.nil?
          Weekly.reccomendation(user).deliver
        end
      end
    else
      user = User.find_by_username("imack")
      Weekly.reccomendation(user).deliver
    end

  end
end