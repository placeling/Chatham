class UsersController < ApplicationController
  before_filter :login_required, :only =>[:follow, :unfollow]

  def show
    @user = User.where(:username => params[:id]).first

    #this is the final step in routes, if this doesn't work its a 404 -iMack
    raise ActionController::RoutingError.new('Not Found') unless !@user.nil?

    respond_to do |format|
      format.json { render :json => @user.as_json({:current_user => current_user}) }
      format.html
    end
  end

  def suggested
    lat = params[:lat].to_f
    long = params[:long].to_f

    @users = User.order_by([:created_at, :desc]).limit(10)

    respond_to do |format|
      format.json { render :json=> {:suggested => @users.as_json({:current_user => current_user}) } }
    end
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

  def following
    @user = User.where(:username => params[:id]).first
    @following = @user.following
    respond_to do |format|
      format.json { render :json => {:following => @following } }
      format.html
    end
  end

end
