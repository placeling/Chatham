
REDIS_CONFIG = YAML.load( File.open( Rails.root.join("config/redis.yml") ) )

redis_base = Redis.new(REDIS_CONFIG[::Rails.env].symbolize_keys!)

Resque.redis = redis_base
Resque.redis.namespace = "resque:placeling"

Resque::Failure::Airbrake.configure do |config|
  config.api_key = '6cdd0c13c32d9b5cbd3ab510033319af'
end

Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Airbrake]
Resque::Failure.backend = Resque::Failure::Multiple

#Resque.schedule = YAML.load_file(File.join(Rails.root, 'config/resque_schedule.yml'))

$redis = Redis::Namespace.new(REDIS_CONFIG[::Rails.env][:namespace], :redis => redis_base)
$redis.flushdb if Rails.env.test?

