if Rails.env.production?
  MIXPANEL_TOKEN = "de55e84dbfc779ff7e9174189255fe2c"
  Chatham::Application.config.middleware.use "Mixpanel::Tracker::Middleware", MIXPANEL_TOKEN
else
  class DummyMixpanel
    def method_missing(m, *args, &block)
      true
    end
  end
end