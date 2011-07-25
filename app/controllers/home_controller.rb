class HomeController < ApplicationController
  def index

    @top_users = User.top_users(10)
    @top_places = Place.top_places(10)
  end

end
