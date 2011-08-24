class PerspectivesController < ApplicationController
  before_filter :login_required, :except =>[:index, :show]

  def new

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

  def nearby
    lat = params[:lat].to_f
    long = params[:long].to_f
    span = params[:span].to_f #needs to be > 0

    #for finding *all* perspectives nearby
    @places = Place.find_all_near(lat, long, span)

    respond_to do |format|
      format.html
      format.json { render :json => {:places => @places} }
    end

  end

end
