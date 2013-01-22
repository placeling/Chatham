class PublisherCategoriesController < ApplicationController
  before_filter :permitted_publisher, :except => [:show, :perspectives]

  def perspectives
    #/publishers/:publisher_id/publisher_category/:id

    @lat = params[:lat].to_f
    @lng = params[:lng].to_f

    @publisher = Publisher.forgiving_find(params['publisher_id'])

    if params['id'] == "all"
      @perspectives = Perspective.near_for_user(@publisher.user, [@lat, @lng])
      @publisher_category = nil
    else
      @publisher_category = @publisher.category_for(params['id'])
      @perspectives = @publisher_category.perspectives(@lat, @lng)
    end


    respond_to do |format|
      format.json { render json: {:perspectives => @perspectives.as_json(:detail_view => true), :publisher_category => @publisher_category} }
    end
  end

  # GET /publishers/1
  # GET /publishers/1.json
  def show
    @publisher = Publisher.forgiving_find(params['publisher_id'])
    @publisher_category = @publisher.category_for(params['id'])

    respond_to do |format|
      format.html { redirect_to edit_publisher_publisher_category_path(@publisher, @publisher_category) }
      format.json { render json: @publisher_category }
    end
  end

  # GET /publishers/new
  # GET /publishers/new.json
  def new
    @publisher = Publisher.find(params[:publisher_id])
    @publisher_category = @publisher.publisher_categories.new({}, TagSearchModule)

    respond_to do |format|
      format.html { render :new, :layout => 'bootstrap' }
      format.json { render json: @publisher_category }
    end
  end

  # GET /publishers/1/edit
  def edit
    @publisher = Publisher.find(params[:publisher_id])
    @publisher_category = @publisher.category_for(params['id'])

    respond_to do |format|
      format.html { render :edit, :layout => 'bootstrap' }
      format.json { render json: @publisher_category }
    end
  end

  # POST /publishers
  # POST /publishers.json
  def create
    @publisher = Publisher.find(params[:publisher_id])
    @publisher_category = @publisher.publisher_categories.build(params[:publisher_category], TagSearchModule)

    respond_to do |format|
      if @publisher_category.save
        format.html { redirect_to edit_publisher_path(@publisher), :layout => 'bootstrap', notice: 'Publisher was successfully created.' }
        format.json { render json: @publisher_category, status: :created, location: @publisher_category }
      else
        format.html { render action: "new" }
        format.json { render json: @publisher_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /publishers/1
  # PUT /publishers/1.json
  def update
    @publisher = Publisher.find(params[:publisher_id])
    @publisher_category = @publisher.category_for(params['id'])

    respond_to do |format|
      if @publisher_category.update_attributes(params[:publisher_category])
        format.html { redirect_to edit_publisher_publisher_category_path(@publisher, @publisher_category), notice: 'Publisher was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :edit, :layout => 'bootstrap' }
        format.json { render json: @publisher_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /publishers/1
  # DELETE /publishers/1.json
  def destroy
    @publisher = Publisher.find(params[:publisher_id])
    @publisher_category = @publisher.category_for(params['id'])
    @publisher_category.destroy

    respond_to do |format|
      format.html { redirect_to @publisher }
      format.json { head :no_content }
    end
  end

end
