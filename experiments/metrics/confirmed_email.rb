metric "Confirmed Email" do
  description "Measures how many users confirm their email addresses"

  def values(from, to)
    vals = []
    (from..to).map do |i|
      if User.where(:created_at.lte => i.next_day).count > 0
        vals << (User.where(:created_at.lte => i.next_day).excludes(:confirmed_at => nil).count + 0.0) / (User.where(:created_at.lt => i.next_day).count +0.0)
      else
        vals << 1.0
      end
    end

    return vals
  end
end