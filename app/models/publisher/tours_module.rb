class ToursModule < PublisherCategory
  belongs_to :tour

  def perspectives(lat, lng)
    tags = self.tags.split(",").join(" ")

    if lat && lng
      perspectives = Perspective.query_near_for_user(self.publisher.user, [lat, lng], tags)
    else
      perspectives = Perspective.query_near_for_user(self.publisher.user, [self.publisher.user.loc[0], self.publisher.user.loc[1]], tags)
    end

    return perspectives
  end

  def as_json(options={})
    super.as_json(options).merge(:tour => self.tour.as_json)
  end

end