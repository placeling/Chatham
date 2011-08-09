class PerspectivesController < ApplicationController
  before_filter :authenticate_user!, :except =>[:index, :show]

  def new

  end

  def show
    @perspective = Perspective.find( params[:id] )

    respond_to do |format|
      format.json { render :json =>@perspective }
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

    @place = Place.find( params[:place_id] )

    @perspective= @place.perspectives.where(:user_id => current_user.id).first

    if params[:perspective]
      @perspective.update_attributes(params[:@perspective])
    end

    if params[:image]
      @picture = @perspective.pictures.build()
      @picture.image = params[:image]
      @picture.title = params[:title]
      @picture.save!
    end
    current_user.save!

    respond_to do |format|
      format.html
      format.json { render :json => @perspective }
    end

    if @perspective.save
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render :json => {:status => 'fail'} }
      end
    end



  end

  def create
    if (params[:google_id])
      @place = Place.find_by_google_id( params[:google_id] )
    else
      @place = Place.find( params[:place_id] )
    end

    @perspective= @place.perspectives.build(params)
    @perspective.client_application = current_client_application unless current_client_application.nil?

    if (params[:lat] and params[:long])
        @perspective.location = [params[:lat].to_f, params[:long].to_f]
        @perspective.accuracy = params[:accuracy]
    else
      @perspective.location = @place.location #made raw, these are by definition the same
      @perspective.accuracy = params[:accuracy]
    end
    @perspective.user = current_user

    if @place.save!
      current_user.save
      @perspective.save

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

end
