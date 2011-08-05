class OauthClientsController < ApplicationController
  #before_filter :authenticate_user!
  before_filter :admin_required
  before_filter :get_client_application, :only => [:show, :edit, :update, :destroy]

  def index
    @client_applications = current_user.client_applications
    @tokens = current_user.tokens.where(:invalidated_at => nil )
  end

  def new
    @client_application = ClientApplication.new
  end

  def create
    @client_application = current_user.client_applications.build(params[:client_application])
    if @client_application.save
      flash[:notice] = t "oauth.registered_successfully"
      redirect_to :action => "show", :id => @client_application.id
    else
      render :action => "new"
    end
  end

  def access_token

    @client_application = ClientApplication.find( params[:id] )

    @user = User.where(:username => params[:username] ).first

    if @user.nil?
      flash[:notice] = t"user.unknown_user"
      redirect_to oauth_client_path(@client_application)
      return
    end
    # get rid of old auth tokens
    @user.tokens.where(:client_application_id =>@client_application.id).delete_all

    request_token = @client_application.create_request_token({:token_creation_override =>true})
    request_token.authorize!( @user )
    request_token.provided_oauth_verifier = request_token.verifier
    @access_token = request_token.exchange!
  end


  def show
  end

  def edit
  end

  def update
    if @client_application.update_attributes(params[:client_application])
      flash[:notice] = t "oauth.updated_client_info"
      redirect_to :action => "show", :id => @client_application.id
    else
      render :action => "edit"
    end
  end

  def destroy
    @client_application.destroy
    flash[:notice] = t "oauth.destroyed_client_application"
    redirect_to :action => "index"
  end

  private
  def get_client_application
    unless @client_application = current_user.client_applications.find(params[:id])
      flash.now[:error] = t "oauth.wrong_app_id"
      raise ActiveRecord::RecordNotFound
    end
  end
end
