require 'httparty'

class ToursController < ApplicationController
  
  before_filter :login_required, :except => [:index, :render_preview, :show]
  
  def index
    @user = User.find_by_username(params[:user_id])
    raise ActionController::RoutingError.new('Not Found') unless !@user.nil?
    
    respond_to do |format|
      format.html
    end
  end
  
  def show
    @tour = Tour.forgiving_find(params[:id])
    raise ActionController::RoutingError.new('Not Found') unless !@tour.nil?
    
    if @tour.published == false && @tour.user != current_user
      raise ActionController::RoutingError.new('Not Found') unless !@tour.nil?
    end
    
    # Owner vs. non-owner
    @tour.perspectives = @tour.active_perspectives
    
    respond_to do |format|
      format.html
    end
  end
  
  def new
    @user = User.find_by_username(params[:user_id])
    raise ActionController::RoutingError.new('Not Found') unless !@user.nil?
    
    if @user != current_user
      raise ActionController::RoutingError.new('Not Found')
    end
    
    @tour = Tour.new
    @tour.user = @user
    
    respond_to do |format|
      format.html
    end
  end
  
  def create
    @user = User.find_by_username(params[:user_id])
    raise ActionController::RoutingError.new('Not Found') unless !@user.nil?
    
    if @user != current_user
      raise ActionController::RoutingError.new('Not Found')
    end
    
    @tour = Tour.new(params[:tour])
    
    @tour.center = [params[:center_lat].to_f, params[:center_lng].to_f]
    @tour.northeast = [params[:northeast_lat].to_f, params[:northeast_lng].to_f]
    @tour.southwest = [params[:southwest_lat].to_f, params[:southwest_lng].to_f]
    @tour.user = @user
    
    if @tour.valid?
      @tour.save()
      return redirect_to(places_user_tour_path(@user, @tour))
    end
    
    render :new
  end
  
  def edit
    @tour = Tour.forgiving_find(params[:id])
    raise ActionController::RoutingError.new('Not Found') unless !@tour.nil?
    
    if @tour.user != current_user
      raise ActionController::RoutingError.new('Not Found')
    end
    
    respond_to do |format|
      format.html
    end
  end
  
  def update
    @tour = Tour.forgiving_find(params[:id])
    raise ActionController::RoutingError.new('Not Found') unless !@tour.nil?
    
    if @tour.user != current_user
      raise ActionController::RoutingError.new('Not Found')
    end
    
    @tour.name = params[:tour][:name]
    @tour.description = params[:tour][:description]
    @tour.zoom = params[:tour][:zoom]
    
    @tour.center = [params[:center_lat].to_f, params[:center_lng].to_f]
    @tour.northeast = [params[:northeast_lat].to_f, params[:northeast_lng].to_f]
    @tour.southwest = [params[:southwest_lat].to_f, params[:southwest_lng].to_f]
    
    # Remove perspectives not in new bounds
    if @tour.position && @tour.position.length > 0
      available_perspectives = Perspective.where(:ploc.within => {"$box" => [[@tour.southwest[0], @tour.southwest[1]], [@tour.northeast[0], @tour.northeast[1]]]}, :uid => @tour.user.id)
      
      clean_perspectives = []
      @tour.position.each do |pid|
        perspective = Perspective.find(pid)
        if available_perspectives.include?(perspective)
          clean_perspectives << pid
        end
      end
      
      @tour.position = clean_perspectives
    end
    
    if @tour.valid?
      @tour.save()
      return redirect_to(places_user_tour_path(@tour.user, @tour))
    end
    
    render :edit    
  end
  
  def places
    @tour = Tour.forgiving_find(params[:id])
    raise ActionController::RoutingError.new('Not Found') unless !@tour.nil?
    
    if @tour.user != current_user
      raise ActionController::RoutingError.new('Not Found')
    end
    
    if !@tour.position
      @tour.position = []
    end
    
    perspectives = Perspective.where(:ploc.within => {"$box" => [[@tour.southwest[0], @tour.southwest[1]], [@tour.northeast[0], @tour.northeast[1]]]}, :uid => @tour.user.id).not_in(:_id => @tour.position)
    
    @perspectives = perspectives.sort {|a,b| a.place.name.downcase <=> b.place.name.downcase}
    
    respond_to do |format|
      format.html
    end
  end
  
  def update_places
    @tour = Tour.forgiving_find(params[:id])
    raise ActionController::RoutingError.new('Not Found') unless !@tour.nil?
    
    if @tour.user != current_user
      raise ActionController::RoutingError.new('Not Found')
    end
    
    @tour.perspectives = []
    @tour.position = []
    if params[:perspectives]
      params[:perspectives].each do |pid|
        persp = Perspective.find(pid)
        puts pid
        puts persp.place.name
        @tour.position << pid
      end
    end
    
    @tour.save
    
    return redirect_to(preview_user_tour_path(@tour.user, @tour))
  end
  
  def preview
    @tour = Tour.forgiving_find(params[:id])
    raise ActionController::RoutingError.new('Not Found') unless !@tour.nil?
    
    if @tour.user != current_user
      raise ActionController::RoutingError.new('Not Found')
    end
    
    respond_to do |format|
      format.html
    end
  end
  
  def publish
    @tour = Tour.forgiving_find(params[:id])
    raise ActionController::RoutingError.new('Not Found') unless !@tour.nil?
    
    if @tour.user != current_user
      raise ActionController::RoutingError.new('Not Found')
    end
    
    @tour.published = true
    @tour.rendered = false
    
    @tour.save
    
    Resque.enqueue(RenderTour, @tour.id, render_preview_user_tour_url(@tour.user, @tour))
    
    return redirect_to(poll_user_tour_path(@tour.user, @tour))
  end
  
  def render_preview
    @tour = Tour.forgiving_find(params[:id])
    raise ActionController::RoutingError.new('Not Found') unless !@tour.nil?
    
    @tour.perspectives = @tour.active_perspectives
    
    render :layout => 'minimal'
  end
  
  def poll
    @tour = Tour.forgiving_find(params[:id])
    raise ActionController::RoutingError.new('Not Found') unless !@tour.nil?
    
    @trivia = TRIVIA.shuffle
    
    # CarrierWave issue: uploads occuring after save, so need to test for file
    @loaded = false
    if @tour.rendered
      response = HTTParty.get(@tour.infographic_url(:screen))
      if response.code == 200
        @loaded = true
      end
    end
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def like_all
    @tour = Tour.forgiving_find(params[:id])
    raise ActionController::RoutingError.new('Not Found') unless !@tour.nil?
    
    perspectives = @tour.active_perspectives
    perspectives.each do |perspective|
      puts perspective.place.name
      puts perspective.starring_users
      if !perspective.starring_users.include?(current_user.id)
        current_user.star(perspective)
      end
    end
    
    respond_to do |format|
      format.js
    end
  end
end
