
REDIS_CONFIG = YAML.load( File.open( Rails.root.join("config/redis.yml") ) )

redis_base = Redis.new(REDIS_CONFIG[::Rails.env].symbolize_keys!)

Resque.redis = redis_base
Resque.redis.namespace = "resque:placeling"
Resque.schedule = YAML.load_file(File.join(Rails.root, 'config/resque_schedule.yml'))

$redis = Redis::Namespace.new(REDIS_CONFIG[::Rails.env][:namespace], :redis => redis_base)
$redis.flushdb if Rails.env.test?
