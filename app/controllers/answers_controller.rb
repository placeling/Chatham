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

    @answer = @question.answers.build( params[:answer] )
    @answer.place = place

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
  end
end
