class PublishersController < ApplicationController

  before_filter :login_required, :except => [:show, :home]
  before_filter :permitted_publisher, :except => [:show, :index, :home]

  # GET /publishers
  # GET /publishers.json
  def index
    @publishers = Publisher.available_for(current_user).entries

    respond_to do |format|
      format.html { render :index, :layout => 'bootstrap' }
      format.json { render json: {publishers: @publishers} }
    end
  end

  # GET /publishers
  # GET /publishers.json
  def home
    @publisher = Publisher.forgiving_find(params[:id])

    respond_to do |format|
      format.html { render :home, :layout => nil }
    end
  end


  # GET /publishers/1
  # GET /publishers/1.json
  def show
    @publisher = Publisher.forgiving_find(params[:id])

    respond_to do |format|
      format.html { redirect_to edit_publisher_path(@publisher) }
      format.json { render json: {publisher: @publisher} }
    end
  end

  # GET /publishers/new
  # GET /publishers/new.json
  def new
    @publisher = Publisher.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: {publisher: @publisher} }
    end
  end

  # GET /publishers/1/edit
  def edit
    @publisher = Publisher.find(params[:id])

    respond_to do |format|
      format.html { render :edit, :layout => 'bootstrap' }
      format.json { render json: {publisher: @publisher} }
    end

  end

  def download_archive
    @publisher = Publisher.find(params[:id])

    Resque.enqueue(SendDataArchive, current_user.id, @publisher.id)

    respond_to do |format|
      format.html { redirect_to edit_publisher_path(@publisher), :notice => "Data Archive sent to #{current_user.email}" }
    end
  end


  def add_member
    @publisher = Publisher.find(params[:id])
    @user = User.find_by_username(params[:user][:username])

    @publisher.permitted_users.push(@user)
    @i = @publisher.permitted_users.count

    respond_to do |format|
      format.html { render :edit, :layout => 'bootstrap' }
      format.js
      format.json { render json: {publisher: @publisher} }
    end
  end

  def remove_member
    @publisher = Publisher.find(params[:id])
    @user = User.find_by_username(params[:username])

    @publisher.permitted_users.delete(@user)

    respond_to do |format|
      format.html { render :edit, :layout => 'bootstrap' }
      format.js { head :no_content }
      format.json { render json: {publisher: @publisher} }
    end
  end


  # POST /publishers
  # POST /publishers.json
  def create
    @publisher = Publisher.new(params[:publisher])

    respond_to do |format|
      if @publisher.save
        format.html { redirect_to :edit, :layout => 'bootstrap', notice: 'Publisher was successfully created.' }
        format.json { render json: @publisher, status: :created, location: @publisher }
      else
        format.html { render action: "new" }
        format.json { render json: @publisher.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /publishers/1
  # PUT /publishers/1.json
  def update
    @publisher = Publisher.find(params[:id])

    respond_to do |format|
      if @publisher.update_attributes(params[:publisher])
        format.html { redirect_to edit_publisher_path(@publisher), notice: 'Publisher was successfully updated.' }
        format.js
        format.json { head :no_content }
      else
        format.html { render :edit, :layout => 'bootstrap' }
        format.js
        format.json { render json: @publisher.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /publishers/1
  # DELETE /publishers/1.json
  def destroy
    @publisher = Publisher.find(params[:id])
    @publisher.destroy

    respond_to do |format|
      format.html { redirect_to publishers_url }
      format.json { head :no_content }
    end
  end
end
