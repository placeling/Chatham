require 'google_places'

class PlacesController < ApplicationController
  before_filter :authenticate_user!, :only => [:create, :new, :update, :destroy]

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
    if params[:google_ref]  #check to see what place data is based on
      if @place = Place.find_by_google_id( params[:google_id] )
        #kind of a no-op
      else
        gp = GooglePlaces.new
        @place = Place.new_from_google_place( gp.get_place( params[:google_ref] ) )
        @place.user = current_user
        @place.save
      end
    else
      @place = Place.new_from_user_input( params )
      @place.user = current_user
      @place.save
    end

    #check for an attached perspective
    if ( params[:memo] )
      @perspective = @place.perspectives.build( )
      @perspective.user = current_user
      @perspective.memo = params[:memo]
      if (params[:lat] and params[:long])
        @perspective.location = [params[:lat].to_f, params[:long].to_f]
        @perspective.accuracy = params[:accuracy]
      end
      @perspective.save! #don't autosave this relation, since were modding at most 1 doc and dont want to bother rest
    end

    if @place.save
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