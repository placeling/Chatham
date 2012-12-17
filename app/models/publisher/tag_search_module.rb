class TagSearchModule < PublisherCategory

  field :tags, :type => String

  def as_json(options={})
    super.as_json(options).merge(:tags => self.tags)
  end

end