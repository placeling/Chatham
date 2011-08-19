class PerspectivesController < ApplicationController
  before_filter :login_required, :except =>[:index, :show]

  def new

  end

  def nearby
    lat = params[:lat].to_f
    long = params[:long].to_f
    radius = params[:accuracy].to_f

    query = params[:query]




    for place in @places
      #add distance to in meters
      place.distance = (1000 * Geocoder::Calculations.distance_between([lat,long], [place.geometry.location.lat,place.geometry.location.lng], :units =>:km)).floor
    end

    #@places = @places.sort_by { |place| place.distance }

    respond_to do |format|
      format.html
      format.json { render :json => @places }
    end



  end

  def show
    @perspective = Perspective.find( params[:id] )

    respond_to do |format|
      format.json { render :json =>@perspective.as_json(:detail_view => true) }
    end

  end

  def index
    @user = User.find_by_username( params[:user_id] )

    if (params[:lat] && params[:long])
      location = [params[:lat].to_f, params[:long].to_f]
    end

    respond_to do |format|
      format.json {
        if ( location )
          render :json => @user.as_json({:perspectives =>:location, :location => location})
        else
          render :json => @user.as_json(:perspectives => :created_by)
        end
      }
      format.html
    end
  end

  def update
    #this can also function as a "create", given that a user can only have one perspective for a place
    if BSON::ObjectId.legal?( params['place_id'] )
      #it's a direct request for a place in our db
      @place = Place.find( params['place_id'])
    else
      @place = Place.find_by_google_id( params['place_id'] )
    end

    @perspective= @place.perspectives.where(:user_id => current_user.id).first

    if @perspective.nil?
      @perspective= @place.perspectives.build(params.slice("memo"))
      @perspective.client_application = current_client_application unless current_client_application.nil?
      @perspective.user = current_user
      if (params[:lat] and params[:long])
          @perspective.location = [params[:lat].to_f, params[:long].to_f]
          @perspective.accuracy = params[:accuracy]
      else
        @perspective.location = @place.location #made raw, these are by definition the same
        @perspective.accuracy = params[:accuracy]
      end
    end

    if params[:perspective]
      @perspective.update_attributes(params[:@perspective])
    end


    if params[:image]
      @picture = @perspective.pictures.build()
      @picture.image = params[:image]
      @picture.title = params[:title]
      @picture.save!
    end

    if @perspective.save
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


  def destroy
    if BSON::ObjectId.legal?( params['place_id'] )
      #it's a direct request for a place in our db
      @place = Place.find( params['place_id'])
    else
      @place = Place.find_by_google_id( params['place_id'] )
    end

    @perspective= @place.perspectives.where(:user_id => current_user.id).first

    if !@perspective.nil?
      @perspective.delete
    end

    respond_to do |format|
      format.html { render :index }
      format.json { render :json => {:status => 'deleted'} }
    end
  end

end
