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
    @question.answers.each do |answer|
      if place.id == answer.place.id
        found = true
        @answer = answer
        break
      end
    end

    if !found
      @answer = @question.answers.build( params[:answer] )
      @answer.place = place
    end

    add_vote_to_history( @answer )

    respond_to do |format|
      if @answer.save
        format.html { redirect_to @question, notice: 'Submitted successfully.' }
        format.json { render json: @answer, status: :created, location: @question }
      else
        format.html { redirect_to @question }
        format.json { render json: @answer.errors, status: :unprocessable_entity }
      end
    end

  end

  def upvote
    @question =Question.find( params['question_id'])
    @answer = @question.answers.where(:_id => params['id']).first

    add_vote_to_history( @answer )

    respond_to do |format|
      if @answer.save
        format.html { redirect_to @question, notice: 'Voted!' }
        format.json { render json: @answer, status: :created, location: @question }
        format.js { render action: "../questions/upvote" }
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
