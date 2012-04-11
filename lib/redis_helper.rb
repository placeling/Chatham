module RedisHelper
  # decode Redis value back to Ruby object
  def self.decode(json)
    self.new(ActiveSupport::JSON.decode(json)["#{self.name.downcase}"])
  end

  # encode Ruby object for Redis
  def encoded
    self.updated_at = nil
    self.to_json
  end

  # helpers to generate Redis keys
  def timestamp
    "#{self.created_at.to_i}"
  end

  def key(str, uid=self.id)
    "#{str}:#{uid}"
  end

  def ukey(str, uid=self.user_id) #for keys needing user_id
    "#{str}:#{uid}"
  end

  def id_s
    id.to_s
  end
end