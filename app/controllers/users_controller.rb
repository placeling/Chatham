class UsersController < ApplicationController

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

end
