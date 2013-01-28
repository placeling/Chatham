source 'http://rubygems.org'

gem 'rails', '3.2.11'
#TODO: unpackage this to not include active record

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'


gem "jquery-rails", "~> 2.1.3"
gem "quiet_assets", ">= 1.0.1", :group => :development

gem "mongoid", "~> 2.4.8"
gem "mongoid_rails_migrations", "~> 0.0.13"

gem "bson_ext", "~> 1.3"

gem "oauth", "0.4.4"
gem "devise", "~> 2.1.0"

gem 'omniauth-facebook'
gem 'omniauth-twitter'

gem "aws-ses", "~> 0.4.4", :require => 'aws/ses'

gem "koala"
gem "twitter"

gem "httparty", "~> 0.9.0"
gem "hashie"
gem 'uuidtools'

gem 'mini_magick'
gem 'carrierwave', "~> 0.6.2"
gem 'fog'
gem 'carrierwave-mongoid', "~> 0.1.1", :require => 'carrierwave/mongoid'

gem "geocoder"
gem "geoip"
gem "execjs"

#gem "oauth-plugin", :path => "../oauth-plugin"
gem "oauth-plugin", :git => "git://github.com/placeling/oauth-plugin.git"

gem "twitter-text", :git => "git://github.com/twitter/twitter-text-rb.git"

gem 'airbrake'

gem 'rack-p3p'
gem 'rack-rewrite', '~> 1.2.1'

gem "recaptcha", :require => "recaptcha/rails"

gem "rspec-rails", "~> 2.8.1" #needs these outside to prevent rake break
gem 'ci_reporter'

gem 'mocha'
gem 'factory_girl_rails', "~> 1.1.rc1"
gem "database_cleaner"

gem 'mail_view', :git => 'https://github.com/37signals/mail_view.git'

gem 'nested_form'
gem 'fastercsv'

gem "redis", "~> 2.2"
gem "redis-namespace"
gem 'redis-rails'

gem "mixpanel"
gem 'vanity'

gem 'resque', :require => 'resque/server'
gem 'resque-scheduler', "2.0.0.h", :require => 'resque_scheduler'
gem 'resque_mailer'

gem 'sitemap_generator'
gem 'mongoid_slug'

gem 'rubyzip'
gem 'feedzirra'

group :test, :development do
  gem "parallel_tests"
  gem 'capybara'
  gem 'poltergeist'
end

gem "twitter-bootstrap-rails"

gem 'liquid'

group :assets do
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

gem 'dynamic_form'

gem 'high_voltage'

# Deploy with Capistrano
gem 'capistrano'
gem "capistrano-ext"
gem "rvm-capistrano", :require => false

gem "actionmailer_inline_css"
# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end
