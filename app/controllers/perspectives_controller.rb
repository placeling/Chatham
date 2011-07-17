class PerspectivesController < ApplicationController
  before_filter :authenticate_user!

  def new

  end

  def create

    if params[:google_ref]
      if @place = Place.find_by_google_id( params[:google_id] )
        #kind of a no-op
      else
        gp = GooglePlaces.new
        @place = Place.create_from_google_place( gp.get_place( params[:google_ref] ) )
      end
    end
    current_user.places << @place
    @perspective= @place.perspectives.build(params[:perspective])
    @perspective.user_id = current_user.id

    if @perspective.save
      current_user.save

      respond_to do |format|
        format.html
        format.json { render :json => @perspective }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render :json => {:status => 'fail'} }
      end
    end
  end

end
