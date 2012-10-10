class PhotosController < ApplicationController
  before_filter :login_required

  def create

    #this can also function as a "create", given that a user can only have one perspective for a place
    @place = Place.forgiving_find(params['place_id'])

    @perspective= current_user.perspective_for_place(@place)

    if @perspective.nil?
      @perspective = @place.perspectives.build()
      @perspective.client_application = current_client_application unless current_client_application.nil?
      @perspective.user = current_user
    end
    @perspective.save!

    @picture = @perspective.pictures.build()
    @picture.image = params[:image]
    @picture.save!

    if @perspective.save
      if params[:newphoto]
        respond_to do |format|
          format.html
          format.json { render :json => {:photo => @picture.as_json({:current_user => current_user})} }
        end
      else
        respond_to do |format|
          format.html
          format.json { render :json => @picture.as_json({:current_user => current_user}) }
        end
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render :json => {:status => 'fail'} }
      end
    end

  end

  def destroy
    #doesn't delete, just flags as deleted to be scooped up later
    #this can also function as a "create", given that a user can only have one perspective for a place
    @place = Place.forgiving_find(params['place_id'])

    @perspective= current_user.perspective_for_place(@place)
    @picture = @perspective.pictures.find(params['id'])

    @picture.deleted = true;

    if @picture.save
      respond_to do |format|
        format.json { render :json => {:status => 'done'} }
      end
    else
      respond_to do |format|
        format.json { render :json => {:status => 'fail'} }
      end
    end

  end

end
