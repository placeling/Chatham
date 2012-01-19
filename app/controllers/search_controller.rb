require 'google_places_autocomplete'

class SearchController < ApplicationController
  before_filter :parameters_required, :only=>[:search]
  
  def parameters_required
    if params[:lat].nil? or params[:lng].nil? or params[:input].nil?
      redirect_to root_path
    end
    
    if params[:lat].to_f == 0.0 and params[:lat] != "0.0"
      redirect_to root_path
    end
    
    if params[:lng].to_f == 0.0 and params[:lng] != "0.0"
      redirect_to root_path
    end
    
  end
  
  def search
    @results = []
    
    # places
    lat = params[:lat].to_f
    lng = params[:lng].to_f
    gpa = GooglePlacesAutocomplete.new
    
    @input = params[:input]
    
    raw_places = gpa.suggest(lat, lng, 10000, @input)
    
    if !raw_places.nil?
      raw_places.each do |place|
        interstitial = {}
        interstitial['name'] = place.terms[0].value
        interstitial['url'] = reference_places_path + "?ref=" + place.reference
        location = []
        place.terms.each_with_index do |term, index|
          if index != 0
            location << term.value
          end
        end
        interstitial['location'] = location.join(", ")
        @results << interstitial
      end
    end
    
    # people
    raw_users = User.search_by_username(@input)
    
    if !raw_users.nil?
      raw_users.each do |user|
        interstitial = {}
        interstitial['name'] = user.username
        interstitial['location'] = user.city
        interstitial['url'] = user_path(user)
        interstitial['pic'] = user.thumb_url
        @results << interstitial
      end
    end
    
    respond_to do |format|
      format.html { render :search }
      format.json { render :json => {:results => @results} }
    end
  end
end