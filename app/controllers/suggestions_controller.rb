class SuggestionsController < ApplicationController

  before_filter :login_required, :only => [:create, :index]
  before_filter :admin_required, :only => :destroy

  # GET /suggestions
  # GET /suggestions.json
  def index
    user = User.find(params[:user_id])
    @suggestions = Suggestion.find_suggested_for_user(user)
    return unless user.id == current_user.id

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: {suggestions: @suggestions} }
    end
  end

  # GET /suggestions/1
  # GET /suggestions/1.json
  def show
    @suggestion = Suggestion.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: {suggestion: @suggestion.as_json(:current_user => current_user)} }
    end
  end

  def user_search
    query = params[:query]

    @users = User.search_by_username(query)

    respond_to do |format|
      format.html
      format.json { render :json => {:status => "success", :users => @users.as_json({:current_user => current_user})} }
    end
  end


  # POST /suggestions
  # POST /suggestions.json
  def create
    user = User.find(params[:user_id])

    if params[:suggestion]
      @suggestion = Suggestion.new(params[:suggestion])
    else
      place = Place.find(params['place_id'])
      @suggestion = Suggestion.new(:message => params['message'])
      @suggestion.place = place
    end

    @suggestion.receiver = user
    @suggestion.sender = current_user

    respond_to do |format|
      if @suggestion.save
        ActivityFeed.send_suggestion(@suggestion)
        track! :suggest
        format.html { redirect_to @suggestion, notice: 'Suggestion was successfully created.' }
        format.json { render json: {suggestion: @suggestion}, status: :created, location: @suggestion }
      else
        format.html { render action: "new" }
        format.json { render json: {errors: @suggestion.errors}, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /suggestions/1
  # DELETE /suggestions/1.json
  def destroy
    @suggestion = Suggestion.find(params[:id])
    @suggestion.destroy

    respond_to do |format|
      format.html { redirect_to user_suggestions_url(current_user) }
      format.json { head :no_content }
    end
  end
end
