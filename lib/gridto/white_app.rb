require 'sinatra/reloader' if Rails.env.development?

class WhiteApp < Sinatra::Base
  # To change this template use File | Settings | File Templates.

  configure do
    set :views, File.dirname(__FILE__) + '/views'
    set :public_folder, Proc.new { File.join(root, "static") }
  end

  helpers do
    def bar(name)
      "#{name}bar"
    end
  end

  get "/" do
    erb :index
  end

  get "/category/:category" do
    redirect "/whitelabel/category/#{params[:category]}/list"
  end

  get "/category/:category/list" do

    user = User.find_by_username("gridto")

    @perspectives = Perspective.find_recent_for_user(user, 0, 20)

    erb :categorylist
  end


  get "/category/:category/map" do
    user = User.find_by_username("gridto")

    @perspectives = Perspective.find_recent_for_user(user, 0, 20)

    erb :categorymap
  end

  get "/place/:id" do
    user = User.find_by_username("gridto")
    place = Place.forgiving_find(params[:id])
    @perspective = user.perspective_for_place(place)

    erb :place
  end


end