require 'google_places'
require 'google_reverse_geocode'

class PlacesController < ApplicationController
  before_filter :admin_required, :only => [:new]
  before_filter :login_required, :only => [:create, :new, :update, :destroy, :search]
  
  def reference
    if params[:ref].nil?
      raise ActionController::RoutingError.new('Not Found')
    end
    
    gp = GooglePlaces.new
    place = gp.get_place(params[:ref])
    
    if place.nil?
      raise ActionController::RoutingError.new('Not Found')
    end
    
    @place = Place.find_by_google_id( place.id )
    
    if @place.nil?
      @place = Place.new_from_google_place( place )
      @place.save
    end
    
    redirect_to place_path(@place)
  end
  
  def nearby
    lat = params[:lat].to_f
    lng = params[:lng].to_f
    radius = params[:accuracy].to_f
    gp = GooglePlaces.new

    query = params[:query]

    if lng.nil? || lng == 0
      lng = params[:long].to_f
    end

    if query && query != ""
      @places = gp.find_nearby(lat, lng, radius, query)
    else
      @places = gp.find_nearby(lat, lng, radius)
    end

    for place in @places
      #add distance to in meters
      place.distance = (1000 * Geocoder::Calculations.distance_between([lat,lng], [place.geometry.location.lat,place.geometry.location.lng], :units =>:km)).floor
    end

    #TEST: sort by distance rather than popularity
    #@places = @places.sort_by { |place| place.distance }

    respond_to do |format|
      format.html
      format.json { render :json => {:places => @places } }
    end

  end

  def random
    lat = params[:lat].to_f
    long = params[:lng].to_f

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

  def new
    @place = Place.new
    
    file = File.open(Rails.root.join("config/google_place_mapping.json"), 'r')
    content = file.read()
    @categories = JSON(content)
    
    respond_to do |format|
      format.html
    end
  end

  def suggested
    #doesn't actually return perspectives, just places for given perspectives
    lat = params[:lat].to_f
    lng = params[:lng].to_f

    radius = params[:radius].to_f unless params[:radius].nil?

    query = params[:query]
    category = params[:category]

    if ( params[:socialgraph] && !params[:query_type])
      socialgraph = params[:socialgraph].downcase == "true"
      if socialgraph
        query_type = "following"
      else
        query_type =  "popular"
      end

    elsif ( params[:query_type] )
      query_type =  params[:query_type].downcase
    else
      query_type = "popular"
    end

    barrie = params[:barrie]
    loc = [lat, lng]

    n = 40
    if !radius
      span = 0.04
    else
      span = 0.04
    end
    span = 0.04
    radius = 1000

    #preprocess for query
    if query_type == "following" && current_user
      following_ids = current_user[:following_ids] << current_user.id
      @perspectives = Perspective.query_near( loc, span, query, category ).
        and(:uid.in => following_ids).limit(n).entries
    elsif query_type == "me" && current_user
      search_ids = [ current_user.id ]
      @perspectives = Perspective.query_near( loc, span, query, category ).
        and(:uid.in => search_ids).limit(n).entries
    else
      @perspectives = Perspective.query_near( loc, span, query, category ).limit(n).entries
    end

    @places_dict = {}

    for perspective in @perspectives.entries
      place = perspective.place_stub.to_place #saves lookup, effectively casts stub as real, DONT SAVE

      if current_user && perspective.user.id == current_user.id
        username = "You"
      else
        username =  perspective.user.username
      end
      if @places_dict.has_key?(place.id)
        place = @places_dict[place.id]
        if username == "You"
          place.users_bookmarking.insert(0, username )
        else
          place.users_bookmarking << username
        end
        place.placemarks << perspective
      else
        place.users_bookmarking =  [username]
        @places_dict[place.id] = place
        place.placemarks = [perspective]
      end
    end

    @places = @places_dict.values

    for place in @places
      #add distance to in meters
      place.distance = (1000 * Geocoder::Calculations.distance_between([lat,lng], [place.location[0],place.location[1]], :units =>:km)).floor
    end

    @places = @places.sort_by { |place| place.distance }

    if !barrie.nil? and query_type ==  "popular" and !socialgraph and @places.count < 5
      gp = GooglePlaces.new
      #covers "barrie problem" of no content
      if category != nil and category.strip != ""
        categories_array = CATEGORIES[category].keys + CATEGORIES[category].values
        @google_places = gp.find_nearby(lat, lng, radius, query, true, categories_array)
      else
        @google_places = gp.find_nearby(lat, lng, radius, query)
      end

      for gplace in @google_places
        for place in @places
          if place.id == gplace.id
            @google_places.delete( gplace )
            break
          end
        end
      end

      @processed_google_places = []
      #this doesn't really work
      for gplace in @google_places
        #add distance to in meters
        place = Place.new_from_google_place( gplace )
        @processed_google_places << place
      end

      @places = @places + @processed_google_places

    end

    respond_to do |format|
        format.html
        format.json { render :json => {:suggested_places => @places } }#, :ad => Advertisement.new( "Admob" ) } }
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
      @place = Place.new(params[:place])
      if @place.valid?
        @place = Place.new_from_user_input(@place)
        @place.user = current_user
        @place.client_application = current_client_application unless current_client_application.nil?
        @place.save
      end      
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

    #raise a 404 if the place isn't found
    raise ActionController::RoutingError.new('Not Found') unless !@place.nil?

    @follow_perspectives_count = 0
    
    if current_user
      @my_perspective = current_user.perspective_for_place(@place)
      @following_perspectives = current_user.following_perspectives_for_place( @place )
      @follow_perspectives_count = @following_perspectives.count

      for perspective in @following_perspectives
        @following_perspectives.delete( perspective ) unless !perspective.empty_perspective?
      end
    end if

    @all_perspectives = @place.perspectives.entries
    if @all_perspectives:
      @all_perspectives_count = @all_perspectives.count
    else
      @all_perspectives_count = 0
    end
    
    perspectives_to_delete = []
    
    for perspective in @all_perspectives
      if perspective.empty_perspective?
        perspectives_to_delete << perspective
      elsif @following_perspectives && @following_perspectives.include?(perspective)
        perspectives_to_delete << perspective
      end
    end
    
    for perspective in perspectives_to_delete
      @all_perspectives.delete(perspective)
    end
    
    if @my_perspective and @all_perspectives.include?(@my_perspective)
      @all_perspectives.delete(@my_perspective)
    end
    
    @else_perspective_count = @all_perspectives.count
    
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
