require 'faster_csv'
require 'google_places'

GOOGLE_RADIUS = 50 # Use 50m as if larger, may not see user-created places

class InprogressController < ApplicationController
  before_filter :admin_required
  
  def convert
    user = User.where({:username => params[:user_id]})
    potential = InProgressPerspective.where({:status => "green", :user_id => user[0]._id})
    
    potential.each do |perspec|
      @perspective= perspec.place.perspectives.build
      @perspective.client_application = current_client_application unless current_client_application.nil?
      @perspective.user = perspec.user
      @perspective.location = perspec.place.location #made raw, these are by definition the same
      
      @perspective.memo = perspec.notes
      @perspective.url = perspec.url
      
      @perspective.save
      
      perspec.destroy
    end
    
    respond_to do |format|
      format.html {redirect_to(user_inprogress_path(params[:user_id]))}
    end
  end
  
  def index
    @user = User.where({:username => params[:user_id]})
    
    @red = InProgressPerspective.where({'user_id' => @user[0].id, :status => "red"}).order_by([:name, :asc]).to_a
    @yellow = InProgressPerspective.where({'user_id' => @user[0].id, :status => "yellow"}).order_by([:name, :asc]).to_a
    @green = InProgressPerspective.where({'user_id' => @user[0].id, :status => "green"}).order_by([:name, :asc]).to_a
    @black = InProgressPerspective.where({'user_id' => @user[0].id, :status => "black"}).order_by([:name, :asc]).to_a
    
    respond_to do |format|
      format.html
    end
  end
  
  def map
    @potential_perspective = InProgressPerspective.find(params[:id])
    
    respond_to do |format|
      format.html
    end
  end
  
  def new
    @potential_perspective = InProgressPerspective.new
    
    respond_to do |format|
      format.html
    end
  end
  
  def create
    @potential_perspective = InProgressPerspective.new(params[:potential_perspective])
    
    @potential_perspective.user = User.where(:username=>params[:user_id])[0]
    
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
          perp = InProgressPerspective.new
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
          perp.valid?
          if perp.errors[:url].length > 0
            perp.url = nil
          end
          
          # Check that first row is not header row. 
          if perp.name.downcase != "name"
            perp.save
          end
        end
        format.html { render :action => "index" }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  def edit
    @potential_perspective = InProgressPerspective.find(params[:id])
    @user = User.where(:username=>params[:user_id])[0]
    
    if @potential_perspective.status == "red"
      render :action => "address"
    elsif @potential_perspective.status == "yellow"
      gp = GooglePlaces.new
      @places = gp.find_nearby(@potential_perspective.location[0], @potential_perspective.location[1], GOOGLE_RADIUS)
      @categories = CATEGORIES
      
      render :action => "place"
    elsif @potential_perspective.status == "green"
      render :action => "perspective"
    end
    
  end
  
  def update
    @potential_perspective = InProgressPerspective.find(params[:id])
    
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
      @potential_perspective.place = nil
      @potential_perspective.potential_places = []
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
      @potential_perspective.potential_places = []
    end
    
    # Fixing place - user picked a place
    if params.include?("gid") and params.include?("ref")
      place = Place.find_by_google_id( params[:gid] )
      
      if place.nil?
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
    
    if params.has_key?(:in_progress_perspective)
      # Fixing place - user create a place
      if params[:in_progress_perspective].has_key?(:name)
        if params[:in_progress_perspective][:name].length == 0
          @potential_perspective.errors.add(:base, "We need a name for this place.")
        end
        
        if !params[:in_progress_perspective].has_key?(:venue_types) or params[:in_progress_perspective][:venue_types].length == 0
          @potential_perspective.errors.add(:base, "Please pick at least one venue type")
        elsif params[:in_progress_perspective][:name].length > 0
          @place = Place.new
          @place.name = params[:in_progress_perspective][:name]
          @place.venue_types = params[:in_progress_perspective][:venue_types]
          @place.location = @potential_perspective.location
          
          if @place.valid?
            @place = Place.new_from_user_input(@place)
            @place.user = current_user
            @place.client_application = current_client_application unless current_client_application.nil?
            @place.save!
            
            @potential_perspective.place = @place
          end
        end
      elsif params[:in_progress_perspective].has_key?(:notes)
        @potential_perspective.notes = params[:in_progress_perspective][:notes]
        if params[:in_progress_perspective][:url].length == 0
          @potential_perspective.url = nil
        else
          @potential_perspective.url = params[:in_progress_perspective][:url]
        end
      end
    end
    
    respond_to do |format|
      if @potential_perspective.errors.length == 0
        @potential_perspective.save
        format.html { redirect_to(user_inprogress_path(@potential_perspective.user)) }
      else
        if @potential_perspective.status == "red"
          format.html {render :action => "address"}
        elsif @potential_perspective.status == "yellow"
          @categories = CATEGORIES
          format.html {render :action => "place"}
        elsif @potential_perspective.status == "green"
          format.html {render :action => "perspective"}
        end
      end
    end
  end
  
  def destroy
    @potential_perspective = InProgressPerspective.find(params[:id])
    @potential_perspective.potential_places.delete_all
    @potential_perspective.destroy
    
    respond_to do |format|
      format.html { redirect_to(user_inprogress_path(params[:user_id])) }
    end
  end
end