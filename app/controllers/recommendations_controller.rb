class RecommendationsController < ApplicationController
  def get_entry(blog_id, entry_id)
    blog = Blogger.find(blog_id)
    blog.entries.each do |entry|
      if entry.id.to_s == entry_id
        return entry
      end
    end

    return false
  end

  def nearby

    lat = params[:lat].to_f
    lng = params[:lng].to_f

    geonear = BSON::OrderedHash.new()
    geonear["$near"] = [lat, lng]
    geonear["$maxDistance"] = 0.1

    @bloggers = Blogger.where("entries.location" => geonear).entries
    placed_bloggers = []
    @bloggers.each do |blogger|
      blogger.entries.delete_if { |entry| entry.created_at < 1.week.ago || entry.place_id.nil? }
      placed_bloggers << blogger unless blogger.entries.count == 0
    end

    respond_to do |format|
      format.json { render json: {bloggers: placed_bloggers.as_json({:detail_view => true})} }
    end
  end

end
