class QuestionsController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :destroy, :edit, :update]
  before_filter :admin_required, :only => [:admin]

  # GET /questions
  # GET /questions.json
  def index

    valid_latlng = false
    if params[:lat] && params[:lng]
      valid_lat = false
      valid_lng = false
      if params[:lat]
        lat = params[:lat].to_f
        if lat != 0.0 && lat < 90.0 && lat > -90.0
          valid_lat = true
        end
      end
      if params[:lng]
        lng = params[:lng].to_f
        if lng != 0.0 && lng < 180 && lng > -180
          valid_lng = true
        end
      end
      if valid_lat && valid_lng
        valid_latlng = true
      end
    end

    if valid_latlng
      loc = {}
      loc["lat"] = lat
      loc["lng"] = lng
    else
      loc = get_location
      if loc["remote_ip"]
        loc = loc["remote_ip"]
      else
        loc = loc['default']
      end
    end

    if current_user
      @myQuestions = current_user.questions.order(:created_at, :desc)
    end

    @questions = Question.nearby_questions(loc["lat"].to_f, loc["lng"].to_f).limit(20)

    @question = Question.new
    @question.location = [0.0, 0.0]

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @questions }
    end
  end

  # GET /questions/admin
  def admin
    @questions = Question.all

    respond_to do |format|
      format.html
      format.json { render json: @questions }
    end
  end


  # GET /questions/1
  # GET /questions/1.json
  def show
    if BSON::ObjectId.legal?(params[:id])
      @question = Question.find(params[:id])
    else
      @question = Question.find_by_slug(params[:id])
    end


    if @question.nil?
      raise ActionController::RoutingError.new('Not Found')
    end

    @other_questions = Question.nearby_questions(@question.location[0], @question.location[1]).limit(3).entries

    @other_questions.delete(@question)
    @answer = @question.answers.build

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @question }
    end
  end

  def share
    if BSON::ObjectId.legal?(params[:id])
      @question = Question.find(params[:id])
    else
      @question = Question.find_by_slug(params[:id])
    end

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /questions/new
  # GET /questions/new.json
  def new
    @question = Question.new
    @question.location = [0.0, 0.0]

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @question }
    end
  end

  # POST /questions
  # POST /questions.json
  def create
    @question = Question.new(params[:question])
    @question.user = current_user

    @question.title = "#{ @question.title } in #{ @question.city_name }?"
    @question.location = [0.0, 0.0] unless !@question.location.nil?

    respond_to do |format|
      if @question.safely.save
        @mixpanel.track_event("question_create")
        format.html { redirect_to share_question_path(@question) }
        format.json { render json: @question, status: :created, location: @question }
      else
        format.html { render action: "new" }
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end


  # DELETE /questions/1
  # DELETE /questions/1.json
  def destroy
    if BSON::ObjectId.legal?(params[:id])
      @question = Question.find(params[:id])
    else
      @question = Question.find_by_slug(params[:id])
    end

    @question.destroy if (current_user.id == @question.user.id || current_user.is_admin?)

    respond_to do |format|
      format.html { redirect_to questions_url }
      format.json { head :no_content }
    end
  end
end
