class RecommendationsController < ApplicationController

  def nearby

    lat = params[:lat].to_f
    lng = params[:lng].to_f

    @bloggers = []


    respond_to do |format|
      format.json { render json: {blogggers: @bloggers} }
    end

  end

end
