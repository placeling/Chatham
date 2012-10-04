require 'sinatra/reloader' if Rails.env.development?
require "sinatra/content_for"
require 'rack-ssl-enforcer'

class WhiteApp < Sinatra::Base
  helpers Sinatra::ContentFor
  register Sinatra::Subdomain

  # To change this template use File | Settings | File Templates.
  dir = File.dirname(File.expand_path(__FILE__))
  set :views, "#{dir}views"

  if respond_to? :public_folder
    set :public_folder, "#{dir}/static"
  else
    set :public, "#{dir}/static"
  end

  configure do
    set :views, File.dirname(__FILE__) + '/views'
    set :public_folder, Proc.new { File.join(root, "static") }
  end

  configure :staging do
    set :force_ssl, true
    use Rack::SslEnforcer
  end
  configure :production do
    set :force_ssl, true
    use Rack::SslEnforcer
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
        return Perspective.query_near_for_user(user, [@lat, @lng], 180, tags)
      else
        return Perspective.query_near_for_user(user, [user.loc[0], user.loc[1]], 180, tags)
      end
    end
  end


  subdomain do

    before do
      @base_user = subdomain
      @user = User.find_by_username(subdomain)

      @lat = request.cookies["lat"]
      @lng = request.cookies["lng"]
    end

    get "/" do
      erb :index
    end

    get "/category/:category" do
      redirect "/category/#{params[:category]}/list"
    end

    get "/category/:category/list" do
      @user = User.find_by_username(@base_user)
      @perspectives = get_perspectives(@user, params[:category]).limit(20).entries

      if @lat && @lng
        @perspectives.each do |perspective|
          #add distance to in meters
          perspective.distance = Geocoder::Calculations.distance_between([@lat.to_f, @lng.to_f], [perspective.place.location[0], perspective.place.location[1]], :units => :km)
        end
        @perspectives = @perspectives.sort_by { |perspective| perspective.distance }
      end

      erb :categorylist
    end


    get "/category/:category/map" do
      @user = User.find_by_username(@base_user)

      if @lat && @lng
        @display_lat = @lat
        @display_lng = @lng
      else
        @display_lat = @user.loc[0]
        @display_lng = @user.loc[1]
      end

      erb :categorymap
    end

    get "/place/:id" do
      user = User.find_by_username(@base_user)
      place = Place.forgiving_find(params[:id])
      @perspective = user.perspective_for_place(place)

      erb :place
    end
  end
end