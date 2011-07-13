class UserController < ApplicationController
  def profile
    @user = User.where(:username => params[:username]).first
  end

end
