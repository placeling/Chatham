#we dont' want to keep the secret keys in source control, for now, so it checks in /etc for production, a locally for else'
begin
  secret_keys = YAML.load_file("/etc/chatham/secret_keys.yml")[::Rails.env]
rescue
  secret_keys = YAML.load_file("#{::Rails.root.to_s}/config/secret_keys.yml")[::Rails.env]
end

CHATHAM_CONFIG = secret_keys.merge( YAML.load_file("#{::Rails.root.to_s}/config/chatham_config.yml") )