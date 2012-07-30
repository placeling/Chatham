OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, CHATHAM_CONFIG['facebook_app_id'], CHATHAM_CONFIG['facebook_app_secret'], {:scope => "email, publish_stream, publish_actions,offline_access", :client_options => {:ssl => {:ca_file => "/usr/lib/ssl/certs/ca-certificates.crt"}}}
  provider :twitter, CHATHAM_CONFIG['twitter_consumer_key'], CHATHAM_CONFIG['twitter_secret_key']
end
