class UsersController < ApplicationController
  def profile
    @user = User.where(:username => params['username']).first

    respond_to do |format|
      format.json { render :json => @user }
      format.html
    end
  end

  def list
    @users = User.all
  end

end
