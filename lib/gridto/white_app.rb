require 'sinatra/reloader' if Rails.env.development?
require "sinatra/content_for"

class WhiteApp < Sinatra::Base
  helpers Sinatra::ContentFor
  # To change this template use File | Settings | File Templates.

  configure do
    set :views, File.dirname(__FILE__) + '/views'
    set :public_folder, Proc.new { File.join(root, "static") }
  end

  configure :staging do
    set :host, 'staging.placeling.com'
    set :force_ssl, true
  end
  configure :production do
    set :host, 'www.placeling.com'
    set :force_ssl, true
  end

  helpers do
    def bar(name)
      "#{name}bar"
    end

    def category_to_tags(category)
      if category =="eating"
        return ["brunch", "pizza", "poutine", "cheap", "kidfriendly", "latenight",
                "grilledcheese", "under10bucks", "worththewait", "barbecue", "cookies",
                "sushi", "veganbrunch", "dimsum", "taketheparents"]
      elsif category =="drinking"
        return ["sportsbar", "caesar", "brownliquor", "cocktails"]
      elsif category == "coffee"
        return ["coffee"]
      elsif category =="pizza"
        return ["pizza"]
      elsif category == "poutine"
        return ["poutine"]
      else
        return []
      end
    end

    def get_perspectives(user, category)
      tags = category_to_tags(category).join(" ")

      if @lat && @lng
        perspectives = Perspective.query_near_for_user(user, [@lat, @lng], 180, tags)
      else
        perspectives = Perspective.query_near_for_user(user, [user.loc[0], user.loc[1]], 180, tags)
      end
      return perspectives
    end
  end

  before do
    @lat = request.cookies["lat"]
    @lng = request.cookies["lng"]

  end

  get "/" do
    erb :index
  end

  get "/category/:category" do
    redirect "/whitelabel/category/#{params[:category]}/list"
  end

  get "/category/:category/list" do
    @user = User.find_by_username("gridto")
    @perspectives = get_perspectives(@user, params[:category])
    erb :categorylist
  end


  get "/category/:category/map" do
    @user = User.find_by_username("gridto")
    @perspectives = get_perspectives(@user, params[:category])
    erb :categorymap
  end

  get "/place/:id" do
    user = User.find_by_username("gridto")
    place = Place.forgiving_find(params[:id])
    @perspective = user.perspective_for_place(place)

    erb :place
  end


end