
REDIS_CONFIG = YAML.load( File.open( Rails.root.join("config/redis.yml") ) )

$redis = Redis.new(REDIS_CONFIG[::Rails.env])
$redis.flushdb if Rails.env.test?

Resque.redis = $redis
Resque.redis.namespace = "resque:placeling"
