Chatham::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  #config.action_dispatch.x_sendfile_header = "X-Sendfile"
  config.force_ssl = true

  # For nginx:
  config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this

  config.assets.initialize_on_precompile = false
  config.assets.compress = true
  config.assets.digest = true
  config.action_controller.asset_host = "https://dmpcpg251rpg5.cloudfront.net"

  config.font_assets.origin = 'https://www.placeling.com'
  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "dmznjo0da80tm.cloudfront.net"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify


  config.action_mailer.delivery_method = :ses

  config.action_mailer.raise_delivery_errors = false

  # Only use best-standards-support built into browsers

  config.action_mailer.default_url_options = {:host => 'www.placeling.com', :protocol => 'https'}


end

APNS.pem = "#{Rails.root}/config/certs/apns-prod-cert.pem"
APNS.host = "gateway.push.apple.com"
APNS.feedback_host = 'feedback.push.apple.com'
APNS.cache_connections = true