#we dont' want to keep the secret keys in source control, for now, so it checks in /etc for production, a locally for else'
begin
  secret_keys = YAML.load_file("/etc/chatham/secret_keys.yml")[::Rails.env]
rescue
  secret_keys = YAML.load_file("#{::Rails.root.to_s}/config/secret_keys.yml")[::Rails.env]
end

CHATHAM_CONFIG = secret_keys.merge(YAML.load_file("#{::Rails.root.to_s}/config/chatham_config.yml")[::Rails.env])

file = File.open(Rails.root.join("config/google_place_mapping.json"), 'r')
content = file.read()
CATEGORIES = JSON(content)

file = File.open(Rails.root.join("config/naughty_words.json"), 'r')
content = file.read()
NAUGHTY_WORDS = JSON(content)

file = File.open(Rails.root.join("config/reserved_usernames.json"), 'r')
content = file.read()
RESERVED_USERNAMES = JSON(content)

