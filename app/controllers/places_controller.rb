require 'google_places'

class PlacesController < ApplicationController
  before_filter :authenticate_user!, :only => :create

  def nearby
    lat = params[:lat].to_f
    long = params[:long].to_f
    radius = params[:accuracy].to_f
    gp = GooglePlaces.new
    @places = gp.find_nearby(lat, long, radius)

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
    @place = Place.new_from_user_input( params[:place] )
    @place.user = current_user

    if ( params[:perspective] )
      @perspective = @place.perspectives.build( params[:perspective] )
      @perspective.user = current_user
    end

    if @place.save
      @perspective.save! #don't autosave this relation, since were modding at most 1 doc and dont want to bother rest
      current_user.save!
      flash[:notice] = t "basic.saved"
      respond_to do |format|
        format.html { redirect_to :action => "show", :id => @place.id }
        format.json { render :json => @place }
      end

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
