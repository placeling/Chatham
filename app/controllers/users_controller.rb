class UsersController < ApplicationController

  def perspectives
    @user = User.find_by_username( params[:id] )

    if (params[:location])

    end

    respond_to do |format|
      format.json {
        if (params[:location])
          render :json => @user.as_json({:perspectives =>:location, :location => params[:location]})
        else
          render :json => @user.as_json(:perspectives => :created_by)
        end
      }
      format.html
    end
  end

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
