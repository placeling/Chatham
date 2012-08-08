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

    @placemark_comment = @perspective.placemark_comments.build(params[:placemark_comments])
    @placemark_comment.user = current_user

    #ActivityFeed.answer_question(current_user, @question)

    respond_to do |format|
      if @placemark_comment.save && @perspective.save
        format.json { render json: {placemark_comments: @placemark_comment, status: :created} }
      else
        format.json { render json: @placemark_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def delete


  end
end
