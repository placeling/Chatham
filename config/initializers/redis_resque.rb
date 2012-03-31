
resque_config = YAML.load_file("#{::Rails.root.to_s}/config/resque.yml")
Resque.redis = resque_config[::Rails.env]
Resque.redis.namespace = "resque:placeling"
