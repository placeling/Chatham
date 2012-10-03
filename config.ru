# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

require 'resque/server'
require 'gridto/white_app'

Resque::Server.use Rack::Auth::Basic do |username, password|
  password == "queueitup"
end


map '/resque' do
  run Resque::Server.new
end

map '/whitelabel' do
  run WhiteApp.new("gridto")
end

map '/vancouverdemo' do
  run WhiteApp.new("lindsayrgwatt")
end

map '/' do
  run Chatham::Application
end
