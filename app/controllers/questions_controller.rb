class QuestionsController < ApplicationController
  before_filter :login_required, :only => [:new, :create, :destroy, :edit, :update]
  before_filter :admin_required, :only => [:admin]

  # GET /questions
  # GET /questions.json
  def index

    loc = get_location
    if loc["remote_ip"]
      loc = loc["remote_ip"]
    else
      loc = loc['default']
    end

    if current_user
      @myQuestions = current_user.questions
    else
      @myQuestions = []
    end

    @questions = Question.nearby_questions(loc["lat"].to_f, loc["lng"].to_f).limit(20)

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
