OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, CHATHAM_CONFIG['facebook_app_id'], CHATHAM_CONFIG['facebook_app_secret'], {:scope => "email, publish_stream,offline_access", :client_options => {:ssl => {:ca_file => "/usr/lib/ssl/certs/ca-certificates.crt"}}}
  #provider :gowalla, CHATHAM_CONFIG['gowalla_api_key'], CHATHAM_CONFIG['gowalla_secret_key']
end
