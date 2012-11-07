class Subdomain
  @@mobile_enabled = ['gridto', 'lindsayrgwatt', "imack", "georgiastraight", "vanmag", "vanart"]

  def self.matches?(request)
    request.subdomain.present? && request.subdomain != 'www' && @@mobile_enabled.include?(request.subdomain)
  end
end