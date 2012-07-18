metric "Bookmarking users" do
  description "Measures how many users have bookmarked at least one place in the trailing week"

  def values(from, to)
    vals = []
    (from..to).map do |i|
      if User.where(:created_at.gte => i.prev_day(7), :created_at.lte => i.next_day).count > 0
        vals << (User.where(:created_at.gte => i.prev_day(7), :created_at.lte => i.next_day).excludes(:pc => 0).count + 0.0) / (User.where(:created_at.gte => i.prev_day(7), :created_at.lte => i.next_day).count +0.0)
      else
        vals << 1.0
      end
    end

    return vals
  end
end