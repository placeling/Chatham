require 'google_places_autocomplete'

class SearchController < ApplicationController
  def search
    @results = []
    
    @valid_params = true
    
    if params[:lat].nil? or params[:lng].nil? or params[:input].nil?
      @valid_params = false
    end
    
    if params[:lat].to_f == 0.0 and params[:lat] != "0.0"
      @valid_params = false
    end
    
    if params[:lng].to_f == 0.0 and params[:lng] != "0.0"
      @valid_params = false
    end
    
    if @valid_params
      # places
      @lat = params[:lat].to_f
      @lng = params[:lng].to_f
      gpa = GooglePlacesAutocomplete.new

      @input = params[:input]

      raw_places = gpa.suggest(@lat, @lng, @input)

      if !raw_places.nil?
        raw_places.each do |place|
          interstitial = {}
          # Need to remove "political" and "route" types to stay in sync with mobile client
          if !place.types.include?("political") and !place.types.include?("route")
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
    end
    
    respond_to do |format|
      format.html { render :search }
      format.json { render :json => {:results => @results} }
    end
  end
end