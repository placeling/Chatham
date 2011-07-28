class UsersController < ApplicationController
  before_filter :authenticate_user!, :only =>[:follow, :unfollow]

  def show
    @user = User.where(:username => params[:id]).first

    #this is the final step in routes, if this doesn't work its a 404 -iMack
    raise ActionController::RoutingError.new('Not Found') unless !@user.nil?

    respond_to do |format|
      format.json { render :json => @user }
      format.html
    end
  end

  def index
    @users = User.all
  end

  def follow
    @user = User.where(:username => params[:id]).first

    current_user.follow( @user )

    @user.save!
    current_user.save!

    respond_to do |format|
      format.json { render :text => "OK" }
      format.html { render :show }
    end
  end

  def unfollow
    @user = User.where(:username => params[:id]).first

    current_user.unfollow( @user )

    @user.save!
    current_user.save!

    respond_to do |format|
      format.json { render :text => "OK" }
      format.html { render :show }
    end
  end


  def followers
    @user = User.where(:username => params[:id]).first
    @followers = @user.followers
    respond_to do |format|
      format.json { render :json => {:followers => @followers} }
      format.html
    end
  end

  def followees
    @user = User.where(:username => params[:id]).first
    @followees = @user.followees
    respond_to do |format|
      format.json { render :json => {:followees => @followees} }
      format.html
    end
  end

end
