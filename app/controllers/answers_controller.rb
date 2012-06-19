require 'google_places'

class AnswersController < ApplicationController
  def create
    @question =Question.find( params['question_id'])
    place = Place.find_by_google_id( params['google_id_place'] )

    if place.nil?
      #not here, and we need to fetch it
      gp = GooglePlaces.new
      place = Place.new_from_google_place( gp.get_place( params['google_ref_place'] ) )
      place.user = current_user
      place.save
    end

    found = false
    #check to see if place is already suggested
    score = 0
    @question.answers.each do |answer|
      score += answer.upvotes
      if place.id == answer.place.id
        found = true
        @answer = answer
      end
    end

    if !found
      @answer = @question.answers.build( params[:answer] )
      @answer.place = place
    end

    add_vote_to_history( @answer )
    @question.score = score +1
    @mixpanel.track_event("answer_submit", {:qid => @question.id})

    respond_to do |format|
      if @answer.save && @question.save
        format.html { redirect_to @question, notice: 'Submitted successfully.' }
        format.json { render json: @answer, status: :created, location: @question }
      else
        alert =  @answer.errors[:base][0] unless @answer.errors[:base].nil?
        format.html { redirect_to @question, alert: alert }
        format.json { render json: @answer.errors, status: :unprocessable_entity }
      end
    end

  end

  def upvote
    @question =Question.find( params['question_id'])
    @answer = @question.answers.where(:_id => params['id']).first

    add_vote_to_history( @answer )
    @question.score += 1

    @mixpanel.track_event("upvote", {:qid => @question.id})

    respond_to do |format|
      if @answer.save && @question.save
        format.html { redirect_to @question, notice: 'Voted!' }
        format.json { render json: @answer, status: :created, location: @question }
        format.js
      else
        format.html { redirect_to @question }
        format.json { render json: @answer.errors, status: :unprocessable_entity }
        format.js { render :text => "" }
      end
    end
  end


  private

  def add_vote_to_history( answer )

    if current_user
      if answer.voters.has_key? current_user.id.to_s
        return false
      else
        answer.voters[ current_user.id.to_s ] = true
        answer.upvotes += 1
        return true
      end
    else
      session_id = request.session_options[:id]
      if answer.voters.has_key? session_id.to_s
        return false
      else
        answer.voters[ session_id.to_s ] = true
        answer.upvotes += 1
        return true
      end
    end
  end

end