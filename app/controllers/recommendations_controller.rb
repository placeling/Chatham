class RecommendationsController < ApplicationController

  def nearby

    lat = params[:lat].to_f
    lng = params[:lng].to_f

    geonear = BSON::OrderedHash.new()
    geonear["$near"] = [lat, lng]
    geonear["$maxDistance"] = 1

    @bloggers = Blogger.where("entries.location" => geonear)

    @blogger = @bloggers.first


    @places = {}

    @bloggers.each do |blogger|
      blogger.entries.each do |entry|
        if entry.location && entry.created_at > 1.week.ago
          if entry.place_id

            if @places.has_key? entry.place_id
              @places[entry.place_id] << entry
            else
              @places[entry.place_id] = [entry]
            end
          end
        end
      end
    end

    @popular_places = []
    @river = []

    @places.each do |key, value|
      @place = Place.find(key)
      if value.count > 1
        @place.entries = value
        @popular_places << @place
      else
        @river << [@place, value[0]]
      end
    end

    @popular_places.sort_by! { |place| -place.entries.count }

    @popular_places = @popular_places.first(4)

    @river = @river.first(10)

    respond_to do |format|
      format.json { render json: {places: @popular_places, featured: @blogger, river: @river} }
    end
  end

end
