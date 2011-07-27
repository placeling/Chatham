#we dont' want to keep the secret keys in source control, for now, so it checks in /etc for production, a locally for else'
begin
  CHATHAM_CONFIG = YAML.load_file("/etc/chatham/secret_keys.yml")[::Rails.env]
rescue
  CHATHAM_CONFIG = YAML.load_file("#{::Rails.root.to_s}/config/secret_keys.yml")[::Rails.env]
end