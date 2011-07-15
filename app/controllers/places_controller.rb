require 'google_places'

class PlacesController < ApplicationController


  def nearby_places
    x = params[:x].to_f
    y = params[:y].to_f
    radius = params[:radius].to_f
    gp = GooglePlaces.new
    @places = gp.find_nearby(x, y, radius)

    respond_to do |format|
      format.html
      format.json { render :json => @places }
    end

  end

  def index
    @places = Place.find :all #, :conditions => 'oauth_tokens.invalidated_at is null and oauth_tokens.authorized_at is not null'
  end

  def new
    @place = Place.new
  end

  def create
    @place = current_user.client_applications.build(params[:place])
    if @place.save
      flash[:notice] = t "basic.saved"
      redirect_to :action => "show", :id => @client_application.id
    else
      render :action => "new"
    end
  end

  def show
    @place = Place.find( params[:id] )

    respond_to do |format|
      format.html
      format.json { render :json => @place }
    end
  end

  def edit
    @place = Place.find( params[:id] )
  end

  def update
    if @place.update_attributes(params[:place])
      flash[:notice] = t "place.updated_place"
      redirect_to :action => "show", :id => @place.id
    else
      render :action => "edit"
    end
  end

  def destroy
    #@client_application.destroy
    #flash[:notice] = t "oauth.destroyed_client_application"
    #redirect_to :action => "index"
  end
end
