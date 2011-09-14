class UsersController < ApplicationController
  before_filter :login_required, :only =>[:follow, :unfollow]


  def create
    return unless params[:format] == :json

    #intentionally only takes one password (for now)
    user = User.new(:username =>params[:username],
                    :email =>params[:email],
                    :password =>params[:password],
                    :confirmation_password =>params[:password])

    user.facebook_access_token = params[:facebook_access_token]

    lat = params[:lat].to_f
    long = params[:long].to_f
    user.location = [lat, long]

    user[:fbDict] = params[:fbDict]

    if user.save
      if current_client_application
        #send back some access keys so user can immediately start
        request_token = current_client_application.create_request_token
        request_token.authorize!( user )
        request_token.provided_oauth_verifier = request_token.verifier
        access_token = request_token.exchange!

        respond_to do |format|
          format.json { render :json => {:status =>"success", :token => access_token.to_query } }
        end
      else
        respond_to do |format|
          format.json { render :json => {:status =>"success"} }
        end
      end
    else
      respond_to do |format|
        format.json { render :json => {:status => "fail", :message => user.errors} }
      end
    end
  end

  def show
    @user = User.find_by_username(params[:id])

    #this is the final step in routes, if this doesn't work its a 404 -iMack
    raise ActionController::RoutingError.new('Not Found') unless !@user.nil?

    respond_to do |format|
      format.json { render :json => @user.as_json({:current_user => current_user, :perspectives => :created_by}) }
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
    @user = User.find_by_username( params[:id] )

    current_user.follow( @user )

    @user.save!
    current_user.save!

    respond_to do |format|
      format.json { render :text => "OK" }
      format.html { render :show }
    end
  end

  def unfollow
    @user = User.find_by_username( params[:id] )

    current_user.unfollow( @user )

    @user.save!
    current_user.save!

    respond_to do |format|
      format.json { render :text => "OK" }
      format.html { render :show }
    end
  end


  def followers
    @user = User.find_by_username( params[:id] )
    @followers = @user.followers
    respond_to do |format|
      format.json { render :json => {:followers => @followers} }
      format.html
    end
  end

  def following
    @user = User.find_by_username( params[:id] )
    @following = @user.following
    respond_to do |format|
      format.json { render :json => {:following => @following } }
      format.html
    end
  end

end
