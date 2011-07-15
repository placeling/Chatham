
CHATHAM_CONFIG = YAML.load_file("#{::Rails.root.to_s}/config/secret_keys.yml")[::Rails.env]