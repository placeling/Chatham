class VanityController < ApplicationController
  include Vanity::Rails::Dashboard
  include Vanity::Rails::TrackingImage

  before_filter :admin_required, :except => [:pinta]

  def pinta
    if params["blog_url"]
      if blogger = Blogger.find_by_url(params["blog_url"])
        if !blogger.activated
          track! :pinta_activation
          blogger.activated = true
          blogger.wordpress = true
          blogger.save
        end
      else
        track! :pinta_activation
        Blogger.create(:title => params["blog_name"], :base_url => params["blog_url"], :wordpress => true, :activated => true)
      end
    end

    respond_to do |format|
      format.html { render :nothing => true }
      format.json { render :nothing => true }
    end
  end
end