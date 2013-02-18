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
    if params[:all]
      @blogs = Blogger.all().order_by(:created_at => :desc)
    else
      @blogs = Blogger.where(:auto_crawl => false).order_by(:created_at => :desc)
    end
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