class ThirdPartyUserModule < PublisherCategory
  belongs_to :user

  def perspectives(lat, lng)

    if lat && lng
      perspectives = Perspective.query_near_for_user(self.user, [lat, lng], "")
    else
      perspectives = Perspective.query_near_for_user(self.user, [self.user.loc[0], self.user.loc[1]], "")
    end

    return perspectives
  end

  def as_json(options={})
    super.as_json(options).merge(:user => self.user.as_json)
  end

end