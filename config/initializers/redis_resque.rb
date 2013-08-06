
# REDIS_CONFIG = YAML.load(File.open(Rails.root.join("config/redis.yml"))) opened in application.rb

redis_base = Redis.new(REDIS_CONFIG.symbolize_keys!)
$redis = Redis::Namespace.new(REDIS_CONFIG[:namespace], :redis => redis_base)
$redis.flushdb if Rails.env.test?

