require 'google_places'
require 'google_reverse_geocode'

class PlacesController < ApplicationController
  before_filter :admin_required, :only => [:new]
  before_filter :login_required, :only => [:create, :new, :update, :destroy, :search]

  def nearby
    lat = params[:lat].to_f
    long = params[:long].to_f
    radius = params[:accuracy].to_f
    gp = GooglePlaces.new

    query = params[:query]

    if query && query != ""
      @places = gp.find_nearby(lat, long, radius, query)
    else
      @places = gp.find_nearby(lat, long, radius)
    end


    for place in @places
      #add distance to in meters
      place.distance = (1000 * Geocoder::Calculations.distance_between([lat,long], [place.geometry.location.lat,place.geometry.location.lng], :units =>:km)).floor
    end

    #@places = @places.sort_by { |place| place.distance }

    respond_to do |format|
      format.html
      format.json { render :json => {:places => @places } }
    end

  end

  def random
    lat = params[:lat].to_f
    long = params[:long].to_f

    @place = Place.find_random(lat, long)

    #@places = @places.sort_by { |place| place.distance }

    respond_to do |format|
      format.html { render :show}
      format.json { render :json => @place }
    end

  end
  
  def search
    @user = current_user
    
    if params[:lat] && params[:long] && params[:query] && params[:query].length > 0
      lat = params[:lat].to_f
      long = params[:long].to_f
      radius = 50.0
      gp = GooglePlaces.new
      
      query = params[:query]
      if params[:query].length > 0
        @query = params[:query]
      end
      
      @places = []
      
      # Google Places
      @raw_places = gp.find_nearby(lat, long, radius, query)
      if @raw_places.length > 0
        @raw_places.each do |place|
          @place = Place.find_by_google_id( place.id )
          
          if @place.nil?
            #not here, and we need to fetch it
            gp = GooglePlaces.new
            @place = Place.new_from_google_place( gp.get_place( place.reference ) )
            @place.user = current_user
            @place.client_application = current_client_application unless current_client_application.nil?
            @place.save!
          end
          
          @places.push(@place)
        end
      end
      
      # Our database - need to do as Google doesn't always find places we add (e.g., Siwash Rock)
      # NOTE: This is hacky as do not have case-insensitive search in MongoDB
      query_term = params[:query].strip.split(",")[0]
      if query.length > 0
        our_places = Place.where(:name => query_term)
        if our_places.length > 0
          our_places.each do |our_place|
            if !@places.include? our_place
              @places.push(our_place)
            end
          end
        end
      end
    end
    
    respond_to do |format|
      format.html
    end
  end
  
  def index
    @places = Place.find :all #, :conditions => 'oauth_tokens.invalidated_at is null and oauth_tokens.authorized_at is not null'
  end

  def new
    @place = Place.new
    
    file = File.open(Rails.root.join("config/google_place_mapping.json"), 'r')
    content = file.read()
    @categories = JSON(content)
    
    respond_to do |format|
      format.html
    end
  end

  def create
    return unless (params[:format] == :json or params[:format] == 'json' or current_user.is_admin? == true)
    
    if params[:google_ref]  #check to see what place data is based on
      if @place = Place.find_by_google_id( params[:google_id] )
        #kind of a no-op
      else
        gp = GooglePlaces.new
        @place = Place.new_from_google_place( gp.get_place( params[:google_ref] ) )
        @place.user = current_user
        @place.client_application = current_client_application unless current_client_application.nil?
        @place.save
      end
    else
      puts "POST params are:"
      puts params
      @place = Place.new(params[:place])
      if @place.valid?
        puts "Place is valid"
        @place = Place.new_from_user_input(@place)
        @place.user = current_user
        @place.client_application = current_client_application unless current_client_application.nil?
        @place.save
      else
        puts "Place is not valid"
      end
      
      file = File.open(Rails.root.join("config/google_place_mapping.json"), 'r')
      content = file.read()
      @categories = JSON(content)
      
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
    if BSON::ObjectId.legal?( params[:id] )
      #it's a direct request for a place in our db
      @place = Place.find( params[:id])
    else
      @place = Place.find_by_google_id( params[:id] )
    end

    if @place.nil? && params['google_ref'] # && current_user
      #not here, and we need to fetch it
      gp = GooglePlaces.new
      @place = Place.new_from_google_place( gp.get_place( params['google_ref'] ) )
      @place.user = current_user
      @place.client_application = current_client_application unless current_client_application.nil?
      @place.save!
    end

    if params['rf']
      @referring_user = User.find_by_username( params['rf'] )
    else
      @referring_user = nil
    end

    respond_to do |format|
      format.html
      format.json { render :json => @place.as_json({:detail_view => true, :current_user => current_user, :referring_user =>@referring_user}) }
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
