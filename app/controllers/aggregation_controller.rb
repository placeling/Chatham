class AggregationController < ApplicationController

  def index

    if params[:lat].nil? || params[:lng].nil?
      @users = User.top_nearby(@default_lat.to_f, @default_lng.to_f, 6)
    else
      @users = User.top_nearby(params[:lat], params[:lng], 6)
    end

    @places = Place.top_nearby_places(@default_lat.to_f, @default_lng.to_f, 0.2, 16)

    respond_to do |format|
      format.html { render :layout => 'bootstrap' }
    end

  end

end
