require 'google_places'
require 'google_reverse_geocode'

class PlacesController < ApplicationController
  before_filter :login_required, :only => [:new, :confirm, :create, :new, :update, :destroy, :highlight, :unhighlight]
  
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

    lat = params[:lat].to_f
    lng = params[:lng].to_f

    if ( params[:long] )
      lng = params[:long].to_f
    end
    
    if lat && lng && params[:query] && params[:query].length > 0
      radius = 500
      gp = GooglePlaces.new
      
      query = params[:query]
      if params[:query].length > 0
        @query = params[:query]
      end
      
      @places = []
      
      # Google Places
      @raw_places = gp.find_nearby(lat, lng, radius, query)
      if @raw_places.length > 0
        @raw_places.each do |place|
          @place = Place.find_by_google_id( place.id )
          
          if @place.nil?
            #not here, and we need to fetch it
            gp = GooglePlaces.new
            @place = Place.new_from_google_place( gp.get_place( place.reference ) )
            @place.user = current_user unless current_user.nil?
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
      format.json { render :json => {:places => @places.as_json( {:current_user => current_user, :user_view => true} ) }, :callback => params[:callback]  }
    end
  end

  def new
    @place = Place.new
    @place.venue_types = [""]
    @place.name = params[:name] unless params[:name].nil?
    
    if !params[:lat].nil?
      @lat = params[:lat].to_f
    else
      @lat = 0.0
    end
    
    if !params[:lng].nil?
      @lng = params[:lng]
    else
      @lng = 0.0
    end
    
    file = File.open(Rails.root.join("config/google_place_mapping.json"), 'r')
    content = file.read()
    @categories = JSON(content)
    @categories.each_pair do |key, val|
      val.each_pair do |k,v|
        val[k] = k #otherwise mapping to google
      end
    end
    
    if request.referer.nil?
      @return_url = "/"
    else
      if URI(request.referer).path == new_user_session_path
        @return_url = session[:"user_return_to"]
      else
        @return_url = request.referer
      end
    end
    
    respond_to do |format|
      format.html
    end
  end

  def confirm
    unless params['place']['address_components'].nil?
      params['place']['address_components'] =JSON.parse( params['place']['address_components'] )
      params['place']['address_components'] = params['place']['address_components'].each{|item| Hashie::Mash.new(item)}
      
      address_array = []
      for component in params['place']['address_components']
         address_array <<  Hashie::Mash.new( component )
      end
      
      address_dict = GooglePlaces.getAddressDict( address_array )
      
      if address_dict['number'] and address_dict['street']
        params['place']['street_address'] = address_dict['number'] + " " + address_dict['street']
      elsif address_dict['street']
         params['place']['street_address'] = address_dict['street']
      end
      
      if address_dict['city'] and address_dict['province']
        params['place']['city_data'] = address_dict['city'] + ", " + address_dict['province']
      end
      
      params['place'].delete( 'address_components' )
    end
    
    @place = Place.new( params[:place] )
    
    if @place.valid?
      render :action => :confirm
    else
      if !@place.location.nil?
        @lat = @place.location[0]
        @lng = @place.location[1]
      end
      
      file = File.open(Rails.root.join("config/google_place_mapping.json"), 'r')
      content = file.read()
      @categories = JSON(content)
      @categories.each_pair do |key, val|
        val.each_pair do |k,v|
          val[k] = k #otherwise mapping to google
        end
      end
      if @place.venue_types.length ==0
        @place.venue_types = [""]
      end
      render :action => :new
    end
  end

  def suggested
    t = Time.now
    #doesn't actually return perspectives, just places for given perspectives
    lat = params[:lat].to_f
    lng = params[:lng].to_f

    span = params[:span].to_f unless params[:span].nil?

    query = params[:query]
    category = params[:category]

    if ( params[:query_type] )
      query_type =  params[:query_type].downcase
    else
      query_type = "popular"
    end

    loc = [lat, lng]

    n = 1000
    if !span
      span = 0.04
    end
    radius = 1000

    #preprocess for query
    if query_type == "following" && current_user
      following_ids = current_user[:following_ids] << current_user.id
      @perspectives = Perspective.query_near( loc, span, query, category ).
        and(:uid.in => following_ids).includes(:user, :place).limit(n).entries
    elsif query_type == "me" && current_user
      search_ids = [ current_user.id ]
      @perspectives = Perspective.query_near( loc, span, query, category ).
        and(:uid.in => search_ids).includes(:user, :place).limit(n).entries
    else
      @perspectives = Perspective.query_near( loc, span, query, category ).includes(:user, :place).limit(n).entries
    end

    @places_dict = {}

    @perspectives.each do |perspective|
      place = perspective.place #saves lookup, effectively casts stub as real, DONT SAVE

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

    @places.delete_if do |place|
      if place.location.nil?
        Rails.logger.warn "NULL LOCATION - #{place.name}, #{place.id}"
        true
      end
    end

    @places.each do |place|
      #add distance to in meters
      place.distance = (1000 * Geocoder::Calculations.distance_between([lat,lng], [place.location[0],place.location[1]], :units =>:km)).floor
    end

    @places = @places.sort_by { |place| place.distance }

    if query_type ==  "popular" and @places.count < 5
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

    logger.info "action: #{(Time.now - t) *1000}ms"
    respond_to do |format|
        format.html
        format.json { render :json => {:suggested_places => @places.as_json({:current_user =>current_user}) } }#, :ad => Advertisement.new( "Admob" ) } }
    end

  end


  def create

    if params[:api_call]
      params[:place] = realign_place_params params
    end
    @place = Place.new(params[:place])
    if @place.valid?
      @place = Place.new_from_user_input(@place)
      track! :user_created_place
      @place.user = current_user
      @place.client_application = current_client_application unless current_client_application.nil?
    end

    if ( params[:api_call] || verify_recaptcha(:model => @place, :message => "Invalid CAPTCHA")) && @place.save
      #by default, we placemark the new place
      track! :placemark
      @perspective= @place.perspectives.build()
      @perspective.user = current_user
      @perspective.save

      respond_to do |format|
        format.html { redirect_to :action => "show", :id => @place.id }
        format.json { render :json => {:place => @place.as_json({:current_user => current_user}), :status =>"OK" } }
      end
    else
      respond_to do |format|
        format.html { render :action => "confirm" }
        format.json { render :json => {:status => "fail"} }
      end
    end
  end


  def highlight
    if BSON::ObjectId.legal?( params[:id] )
      #it's a direct request for a place in our db
      @place = Place.find( params[:id])
    else
      @place = Place.find_by_google_id( params[:id] )
    end

    current_user.highlighted_places << @place.id
    current_user.save

    respond_to do |format|
      format.json { render :json => {:status => "OK"} }
    end

  end

  def unhighlight
    if BSON::ObjectId.legal?( params[:id] )
      #it's a direct request for a place in our db
      @place = Place.find( params[:id])
    else
      @place = Place.find_by_google_id( params[:id] )
    end

    current_user.highlighted_places.delete( @place.id )
    current_user.save

    respond_to do |format|
      format.json { render :json => {:status => "OK"} }
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
      @following_perspectives_empty = []
      @follow_perspectives_count = @following_perspectives.count
      
      for perspective in @following_perspectives
        if perspective.empty_perspective?
          @following_perspectives_empty << perspective
          @following_perspectives.delete(perspective)
        end
      end
    end if

    @all_perspectives = @place.perspectives.entries
    @all_perspectives_empty = []
    if @all_perspectives
      @all_perspectives_count = @all_perspectives.count
    else
      @all_perspectives_count = 0
    end
    
    perspectives_to_delete = []
    
    for perspective in @all_perspectives
      if perspective.empty_perspective? && perspective != @my_perspective
        if @following_perspectives_empty
          if !@following_perspectives_empty.include?(perspective)
            @all_perspectives_empty << perspective
          end
        else
          @all_perspectives_empty << perspective
        end
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
    
    @else_perspective_count = @all_perspectives.count + @all_perspectives_empty.count
    
    if params['rf']
      @referring_user = User.find_by_username( params['rf'] )
    else
      @referring_user = nil
    end

    respond_to do |format|
      format.html
      format.json { render :json => @place.as_json({:detail_view => true, :current_user => current_user, :referring_user =>@referring_user}), :callback => params[:callback]  }
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


  protected
  def realign_place_params( params )
    place = {}
    place[:name] = params.delete(:name)
    place[:street_address] = params.delete(:street_address)
    place[:city_data] = params.delete(:city_data)
    place[:location] = [params.delete(:place_lat), params.delete(:place_lng)]
    place[:venue_types] = []
    place[:venue_types] << params.delete(:initial_venue_type)

    return place
  end
end
