class UsersController < ApplicationController
  def profile
    @user = User.where(:username => params['username']).first

    #this is the final step in routes, if this doesn't work its a 404 -iMack
    raise ActionController::RoutingError.new('Not Found') unless !@user.nil?

    respond_to do |format|
      format.json { render :json => @user }
      format.html
    end
  end

  def list
    @users = User.all
  end

  def perspectives
    @user = User.find_by_username( params[:username] )

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

end
