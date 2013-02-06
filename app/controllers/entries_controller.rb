#update_place_blog_entry POST   /blogs/:blog_id/entries/:id/update_place(.:format)                        entries#update_place

class EntriesController < ApplicationController
  before_filter :admin_required
  
  def place
    blog = Blogger.where("entries._id"=>BSON::ObjectId(params[:id])).first()
    
    blog.entries.each do |entry|
      if entry.id.to_s == params[:id]
        @entry = entry
        break
      end
    end
    
    respond_to do |format|
      format.html
    end
  end
  
  def update_place
    
  end
  
end