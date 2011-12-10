Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, CHATHAM_CONFIG['facebook_app_id'], CHATHAM_CONFIG['facebook_app_secret']
  #provider :gowalla, CHATHAM_CONFIG['gowalla_api_key'], CHATHAM_CONFIG['gowalla_secret_key']
end
