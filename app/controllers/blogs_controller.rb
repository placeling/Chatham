class BlogsController < ApplicationController
  before_filter :admin_required
  
  def new
    @blog = Blogger.new
    @action = 'create'
    
    respond_to do |format|
      format.html
    end
  end
  
  def create
    @blog = Blogger.new(params[:blogger])
    
    place = Place.find_by_google_id(params[:gid])
    if place.nil?
      gp = GooglePlaces.new
      place = gp.get_place(params[:reference])
      place = Place.new_from_google_place(place)
      place.save
    end
    
    @blog.place = place
    @blog.pid = place.id.to_s
    @blog.save
    
    respond_to do |format|
      if @blog.save
        format.html { redirect_to blogs_path, notice: 'Blog was successfully created.' }
      else
        format.html { render action: "new" }
      end
    end
  end
  
  def edit
    @blog = Blogger.find_by_slug(params[:id])
    @action = 'update'
    
    respond_to do |format|
      format.html
    end
  end
  
  def update
    @blog = Blogger.find_by_slug(params[:id])
    @blog.update_attributes(params[:blogger])
    
    if params[:gid]
      place = Place.find_by_google_id(params[:gid])
      if place.nil?
        gp = GooglePlaces.new
        place = gp.get_place(params[:reference])
        place = Place.new_from_google_place(place)
        place.save
      end
    
      @blog.place = place
      @blog.pid = place.id.to_s
      @blog.save
    end
    
    respond_to do |format|
      if @blog.save
        format.html { redirect_to blogs_path, notice: 'Blog was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end
  
  def destroy
    @blog = Blogger.find_by_slug(params[:id])
    @blog.delete
    respond_to do |format|
      format.html { redirect_to blogs_path, notice: 'Blog deleted.' }
    end
  end
  
  def index
    grouped = Blogger.group_by_place
    @cities = []
    
    grouped.each do |city|
      if city["pid"] and !city["pid"].nil?
        place = Place.find(city["pid"])
        @cities << {"place"=>place, "count"=>city["count"].to_i}
      end
    end
    
    respond_to do |format|
      format.html
    end
  end

  def all
    @blogs = Blogger.all().order_by(:created_at => :desc)
  end
  
  def show
    @blog = Blogger.find_by_slug(params[:id])
    
    respond_to do |format|
      format.html
    end
  end
  
  def update_feed
    @blogger = Blogger.find_by_slug(params[:id])
    
    @last_date = @blogger.last_entry_date
    
    @blogger.update_rss_feed
    
    @new_last_date = @blogger.last_entry_date
    
    respond_to do |format|
      format.js
    end
  end
  
  def empty_feed
    blogger = Blogger.find_by_slug(params[:id])
    
    blogger.empty_feed
    
    respond_to do |format|
      format.js
      format.html {redirect_to blogs_path, notice: "Feed emptied"}
    end
  end
end