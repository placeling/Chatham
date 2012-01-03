class Oauth2Token < AccessToken

  def self.find_by_token(token_string)
    where(:token => token_string).first
  end

  def as_json(options={})
    {:access_token=>token}
  end
end
