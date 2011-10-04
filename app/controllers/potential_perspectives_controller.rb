require 'faster_csv'
require 'google_places'

class PotentialPerspectivesController < ApplicationController
  before_filter :admin_required

  def potential_to_real
    user = User.where({:username => params[:user_id]})
    potential = PotentialPerspective.where({:status => "green", :user_id => user[0]._id})
    
    potential.each do |perspec|
      perp = Perspective.new
      
      perp.memo = perspec.notes
      perp.user = perspec.user
      perp.place = perspec.place
      perp.url = perspec.url
      
      perp.save
      
      perspec.destroy
    end
    
    respond_to do |format|
      format.html {redirect_to user_potential_perspectives_path(user[0])}
    end
  end
  
  def index
    @user = User.where({:username => params[:user_id]})
    
    @red = PotentialPerspective.where({'user_id' => @user[0].id, :status => "red"}).to_a
    @yellow = PotentialPerspective.where({'user_id' => @user[0].id, :status => "yellow"}).to_a
    @green = PotentialPerspective.where({'user_id' => @user[0].id, :status => "green"}).to_a
    @black = PotentialPerspective.where({'user_id' => @user[0].id, :status => "black"}).to_a
    
    respond_to do |format|
      format.html
    end
  end

  def new
    @potential_perspective = PotentialPerspective.new

    respond_to do |format|
      format.html
    end
  end

  def edit
    @potential_perspective = PotentialPerspective.find(params[:id])
    
    if @potential_perspective.status == "red"
      render :action => "address"
    elsif @potential_perspective.status == "yellow"
      gp = GooglePlaces.new
      
      # BAD: hard-coded arbitrary radius
      # Don't include name of place as query as Google does exact string matching. Instead shrink radius
      @places = gp.find_nearby(@potential_perspective.location[0], @potential_perspective.location[1], 150)
      
      @categories = CATEGORIES
      
      render :action => "place"
    elsif @potential_perspective.status == "green"
      render :action => "perspective"
    end
    
  end

  def create
    @potential_perspective = PotentialPerspective.new(params[:potential_perspective])
    
    if @potential_perspective.user.nil?
      @potential_perspective.errors.add_to_base "We need a valid username"
    end
    
    if params[:upload].nil?
      @potential_perspective.errors.add_to_base "Please attach a file"
    else
      begin
        data = FasterCSV.parse(params[:upload].read)
      rescue
        @potential_perspective.errors.add_to_base "That .csv file isn't valid"
      end
    end
    
    respond_to do |format|
      if @potential_perspective.errors.length == 0
        # In following, order of fields is hardcoded and assumes no header row
        data.each_with_index do |row, index|
          perp = PotentialPerspective.new
          perp.user = @potential_perspective.user
          perp.name = row[0]
          perp.notes = row[8]
          perp.location = []
          perp.location.push(row[6].to_f)
          perp.location.push(row[7].to_f)
          perp.address = row[1]
          perp.locality = row[2]
          perp.state_prov = row[3]
          perp.country = row[4]
          perp.postal_code = row[5]
          perp.url = row[9]
          puts row[9]
          perp.valid?
          if perp.errors[:url].length > 0
            perp.url = nil
          end
          perp.save
        end
        format.html {redirect_to user_potential_perspectives_path(@potential_perspective.user)}
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @potential_perspective = PotentialPerspective.find(params[:id])
    
    params.each do |key, value|
      puts key
      puts value
    end
    
    #return
    
    # Fixing address
    if params.include?("location")
      if params[:location].length != 2
        lat = 0.0
        lng = 0.0
      else
        lat = params[:location][0].to_f
        lng = params[:location][1].to_f
      end
      
      @potential_perspective.location = []
      @potential_perspective.location.push(lat)
      @potential_perspective.location.push(lng)
    end
    
    # Fixing address - reset it
    if params.include?("address")
      @potential_perspective.location = []
      @potential_perspective.address = nil
      @potential_perspective.locality = nil
      @potential_perspective.state_prov =nil
      @potential_perspective.country = nil
      @potential_perspective.postal_code = nil
    end
    
    # Fixing place - user picked existing
    if params.include?("id") and params.include?("ref")
      place = Place.find_by_google_id( params[:id] )
      
      if @place.nil?
        gp = GooglePlaces.new
        place = Place.new_from_google_place( gp.get_place( params[:ref] ) )
        place.user = current_user
        place.client_application = current_client_application unless current_client_application.nil?
        place.save!
      end
      
      @potential_perspective.name = place.name
      @potential_perspective.place = place
      @potential_perspective.location[0] = place.location[0]
      @potential_perspective.location[1] = place.location[1]
    end
    
    # Fixing place - reset it
    if params.has_key?(:dropplace)
      @potential_perspective.place = nil
      # need to reset address or will simply be re-found
      @potential_perspective.location = []
      @potential_perspective.address = nil
      @potential_perspective.locality = nil
      @potential_perspective.state_prov =nil
      @potential_perspective.country = nil
      @potential_perspective.postal_code = nil
    end
    
    if params.has_key?(:potential_perspective)
      # Fixing place - user creating new place
      if params[:potential_perspective].has_key?(:name)
        if params[:potential_perspective][:name].length == 0
          @potential_perspective.errors.add_to_base "We need a name for this place."
        end
        
        if !params[:potential_perspective].has_key?(:venue_types) or params[:potential_perspective][:venue_types].length == 0
          puts "I'm adding a venue-type error"
          @potential_perspective.errors.add_to_base "Please pick at least one venue type"
        elsif params[:potential_perspective][:name].length > 0
          @place = Place.new
          @place.name = params[:potential_perspective][:name]
          @place.venue_types = params[:potential_perspective][:venue_types]
          @place.location = @potential_perspective.location
          
          if @place.valid?
            @place = Place.new_from_user_input(@place)
            @place.user = current_user
            @place.client_application = current_client_application unless current_client_application.nil?
            @place.save
          end
        end
      #Fixing place - change notes
      elsif params[:potential_perspective].has_key?(:notes)
        @potential_perspective.notes = params[:potential_perspective][:notes]
        if params[:potential_perspective][:url].length == 0
          @potential_perspective.url = nil
        else
          @potential_perspective.url = params[:potential_perspective][:url]
        end
      end
    end
    
    respond_to do |format|
      if @potential_perspective.errors.length == 0
        if @potential_perspective.save
          format.html { redirect_to(user_potential_perspectives_path(@potential_perspective.user), :notice => 'Potential perspective was successfully updated.') }
        else
          if @potential_perspective.status == "red"
            format.html {render :action => "address"}
          elsif @potential_perspective.status == "yellow"
            gp = GooglePlaces.new
            @places = gp.find_nearby(@potential_perspective.location[0], @potential_perspective.location[1], 150)
            @categories = CATEGORIES
            format.html {render :action => "place"}
          elsif @potential_perspective.status == "green"
            format.html {render :action => "perspective"}
          end
        end
      else
        if @potential_perspective.status == "red"
          format.html {render :action => "address"}
        elsif @potential_perspective.status == "yellow"
          gp = GooglePlaces.new
          @places = gp.find_nearby(@potential_perspective.location[0], @potential_perspective.location[1], 150)
          @categories = CATEGORIES
          format.html {render :action => "place"}
        elsif @potential_perspective.status == "green"
          format.html {render :action => "perspective"}
        end
      end
    end
  end

  def destroy
    @potential_perspective = PotentialPerspective.find(params[:id])
    @potential_perspective.destroy

    respond_to do |format|
      format.html { redirect_to(user_potential_perspectives_path(@potential_perspective.user)) }
    end
  end
end
