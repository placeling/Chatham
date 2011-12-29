
resque_config = YAML.load_file("#{::Rails.root.to_s}/config/resque.yml")
Resque.redis = resque_config[::Rails.env]

Resque::Server.use(Rack::Auth::Basic) do |user, password|
  password == "queueitup"
end