require 'sinatra/reloader' if development?

class WhiteApp < Sinatra::Base
  # To change this template use File | Settings | File Templates.

  configure do
    set :views, File.dirname(__FILE__) + '/views'
    set :public_folder, Proc.new { File.join(root, "static") }
  end

  get "/" do
    erb :index
  end


end