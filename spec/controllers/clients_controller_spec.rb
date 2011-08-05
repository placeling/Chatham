require 'spec_helper'

describe OauthClientsController do
  if defined?(Devise)
    include Devise::TestHelpers
  end

  before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = Factory.create(:admin)
      sign_in @user

      @client_application = Factory.build(:client_application, :user => @user)
      @oauth_token = Factory.create(:access_token, :user =>@user, :client_application => @client_application)
      @client_applications = @user.client_applications
      @client_application.save
  end

  describe "index" do

    it "should be successful" do
      get :index
      response.should be_success
    end

    it "should assign client_applications" do
      get :index
      assigns[:client_applications].should==@client_applications
    end

    it "should render index template" do
      get :index
      response.should render_template('index')
    end
  end

  describe "show" do

    it "should be successful" do
      get :show, :id => @client_application.id
      response.should be_success
    end

    #I not sure why this was in here, current_client_application may have been in the helper I removed -iMack
    #it "should assign client_applications" do
    #  get :show, :id => @client_application.id
    #  assigns[:client_application].should==current_client_application
    #end

    it "should render show template" do
      get :show, :id => @client_application.id
      response.should render_template('show')
    end

  end

  describe "new" do

    it "should be successful" do
      get :new
      response.should be_success
    end

    it "should assign client_applications" do
      get :new
      assigns[:client_application].class.should==ClientApplication
    end

    it "should render show template" do
      get :new
      response.should render_template('new')
    end

  end

  describe "edit" do
    def do_get
      get :edit, :id => @client_application.id
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render edit template" do
      do_get
      response.should render_template('edit')
    end

  end

  describe "create" do

    def do_valid_post
      post :create, 'client_application'=>{'name' => 'my site', :url=>"http://test.com"}
      @client_application = ClientApplication.last
    end

    def do_invalid_post
      post :create
    end

    it "should redirect to new client_application" do
      do_valid_post
      response.should be_redirect
      response.should redirect_to(:action => "show", :id => @client_application.id)
    end

    it "should render show template" do
      do_invalid_post
      response.should render_template('new')
    end
  end

  describe "destroy" do

    def do_delete
      delete :destroy, :id => @client_application.id
    end

    it "should destroy client applications" do
      do_delete
      ClientApplication.where(:id => @client_application.id).first.should be_nil
    end

    it "should redirect to list" do
      do_delete
      response.should be_redirect
      response.should redirect_to(:action => 'index')
    end

  end

  describe "update" do

    def do_valid_update
      put :update, :id => @client_application.id, 'client_application'=>{'name' => 'updated site'}
    end

    def do_invalid_update
      put :update, :id => @client_application.id, 'client_application'=>{'name' => nil}
    end

    it "should redirect to show client_application" do
      do_valid_update
      response.should be_redirect
      response.should redirect_to(:action => "show", :id => @client_application.id)
    end

    it "should assign client_applications" do
      do_invalid_update
      assigns[:client_application].should == ClientApplication.find( @client_application.id)
    end

    it "should render show template" do
      do_invalid_update
      response.should render_template('edit')
    end
  end
end
