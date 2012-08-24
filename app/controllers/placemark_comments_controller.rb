class PlacemarkCommentsController < ApplicationController
  before_filter :login_required, :only => [:create, :destroy]

  def index
    @perspective = Perspective.find(params['perspective_id'])

    respond_to do |format|
      format.json { render :json => {:placemark_comments => @perspective.placemark_comments, :status => "OK"} }
    end
  end

  def create
    @perspective = Perspective.find(params['perspective_id'])

    if params[:placemark_comment]
      @placemark_comment = @perspective.placemark_comments.build(params[:placemark_comment])
    else
      @placemark_comment = @perspective.placemark_comments.build(:comment => params[:comment])
    end
    @placemark_comment.user = current_user

    ActivityFeed.comment_placemark(current_user, @placemark_comment)

    respond_to do |format|
      if @perspective.save
        format.json { render json: {placemark_comment: @placemark_comment, status: :created} }
      else
        format.json { render json: @placemark_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def delete


  end
end
