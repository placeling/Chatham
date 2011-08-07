source 'http://rubygems.org'

gem 'rails', '3.0.3'
#TODO: unpackage this to not include active record

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem "jquery-rails"

gem "mongoid", "~> 2.0"
gem "bson_ext", "~> 1.3"

gem "oauth", ">= 0.4.4"
gem "devise", "~> 1.4.2"

gem "system_timer"
gem "httparty"
gem "hashie"

gem 'mini_magick'
gem 'carrierwave'

gem "geocoder"

#gem "oauth-plugin", :path => "../oauth-plugin"
gem "oauth-plugin", :git => "git://github.com/imackinn/oauth-plugin.git"

group :test, :development do
  gem "rspec-rails", "~> 2.6"
  gem 'mocha'
  gem 'json'
  gem 'capybara', :git => 'git://github.com/jnicklas/capybara.git'
  gem 'factory_girl_rails', "~> 1.1.rc1"
  gem 'ci_reporter'
  gem "database_cleaner"
end

# Deploy with Capistrano
gem 'capistrano'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end
