class PerspectivesController < ApplicationController
  before_filter :login_required, :except =>[:index, :show]

  def new

  end

  def following
    if BSON::ObjectId.legal?( params['place_id'] )
      #it's a direct request for a place in our db
      @place = Place.find( params['place_id'])
    else
      @place = Place.find_by_google_id( params['place_id'] )
    end

    @perspectives = current_user.following_perspectives_for_place( @place )
    perspectives_count = @perspectives

    for perspective in @perspectives
      @perspectives.delete( perspective ) unless !perspective.empty_perspective?
    end

    respond_to do |format|
      format.json { render :json => {:perspectives =>@perspectives.as_json({:current_user => current_user, :place_view => true}), :count => perspectives_count} }
    end

  end

  def show
    @perspective = Perspective.find( params[:id] )

    respond_to do |format|
      format.json { render :json =>@perspective.as_json(:current_user => current_user, :detail_view => true) }
    end

  end

  def all
    if BSON::ObjectId.legal?( params['place_id'] )
      #it's a direct request for a place in our db
      @place = Place.find( params['place_id'])
    else
      @place = Place.find_by_google_id( params['place_id'] )
    end

    @perspectives = @place.perspectives
    perspectives_count = @perspectives.count

    for perspective in @perspectives
      @perspectives.delete( perspective ) unless !perspective.empty_perspective?
    end

    respond_to do |format|
      format.json { render :json => {:perspectives =>@perspectives.as_json({:current_user => current_user, :place_view => true}), :count => perspectives_count} }
    end
  end

  def star
    @perspective = Perspective.find( params[:id] )

    current_user.star( @perspective )

    current_user.save
    @perspective.save

    respond_to do |format|
      format.json { render :json =>{:result => "starred"} }
    end
  end

  def unstar
    @perspective = Perspective.find( params[:id] )
    current_user.unstar( @perspective )

    current_user.save
    @perspective.save

    respond_to do |format|
      format.json { render :json =>{:result => "unstarred"} }
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
          render :json => @user.as_json({:current_user => current_user,:perspectives =>:location, :location => location})
        else
          render :json => @user.as_json({:current_user => current_user,:perspectives => :created_by})
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

    @perspective= current_user.perspective_for_place( @place )

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

    if params[:memo]
      @perspective.update_attributes(params.slice("memo"))
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
        format.json { render :json => @perspective.as_json({:current_user => current_user}) }
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

    @perspective= current_user.perspective_for_place( @place )

    if !@perspective.nil?
      @perspective.delete
    end

    respond_to do |format|
      format.html { render :index }
      format.json { render :json => {:status => 'deleted'} }
    end
  end

  def nearby
    #doesn't actually return perspectives, just places for given perspectives
    lat = params[:lat].to_f
    long = params[:long].to_f
    span = params[:span].to_f #needs to be > 0

    if params[:username]
      user = User.find_by_username( params[:username] )
      @places = Place.find_nearby_for_user( user, lat, long, span )
    else
      #for finding *all* perspectives nearby
      @places = Place.find_all_near(lat, long, span)
    end

    respond_to do |format|
      format.html
      format.json { render :json => {:places => @places} }
    end

  end

end
