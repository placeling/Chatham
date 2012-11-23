class PublisherCategoriesController < ApplicationController

  def perspectives
    #/publishers/:publisher_id/publisher_categories/:id

    @lat = params[:lat].to_f
    @lng = params[:lng].to_f

    if BSON::ObjectId.legal?(params['publisher_id'])
      @publisher = Publisher.find(params['publisher_id'])
    else
      @user = User.find_by_username(params['publisher_id'])
      @publisher = @user.publisher
    end

    @publisher_category = @publisher.category_for(params['id'])

    tags = @publisher_category.tags.split(",").join(" ")

    if @lat && @lng
      @perspectives = Perspective.query_near_for_user(@publisher.user, [@lat, @lng], tags)
    else
      @perspectives = Perspective.query_near_for_user(@publisher.user, [@publisher.user.loc[0], @publisher.user.loc[1]], tags)
    end

    respond_to do |format|
      format.json { render json: {:perspectives => @perspectives.as_json(:detail_view => true)} }
    end
  end

end
