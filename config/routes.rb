Chatham::Application.routes.draw do

  get "/feeds/home_timeline",  :to => "home#home_timeline",   :as => :home_feed
  get "admin/terms_of_service", :as => :terms_of_service
  get "admin/privacy_policy", :as => :privacy_policy
  get "admin/about_us", :as => :about_us
  get "admin/contact_us", :as => :contact_us

  root :to => "home#index"

  devise_for :users

  match '/oauth/test_request',  :to => 'oauth#test_request',  :as => :test_request
  match '/oauth/token',         :to => 'oauth#token',         :as => :token
  match '/oauth/access_token',  :to => 'oauth#access_token_with_xauth_test',  :as => :access_token
  match '/oauth/request_token', :to => 'oauth#request_token', :as => :request_token
  match '/oauth/authorize',     :to => 'oauth#authorize',     :as => :authorize
  match '/oauth',               :to => 'oauth#index',         :as => :oauth
  post 'oauth/revoke',          :to => 'oauth#revoke',         :as => :oauth

  resources :users do
    resources :perspectives, :only =>[:index]
    member do
      get :followers
      get :following
      post :follow
      post :unfollow
      get :activity
    end
    collection do
      get :suggested
    end
  end

  resources :perspectives, :only =>[:show]   do
    member do
      post :star
      post :unstar
    end
    collection do
      get :nearby
    end
  end

  resources :places, :except =>[:index] do
    collection do
      get :nearby
      get :random
      get :search
    end
    resources :perspectives, :except =>[:show, :index]  do
      collection do
        resources :photos
        post :update
        post :admin_create
        delete :destroy
        get :following
        get :all
      end
    end
  end

  resources :oauth_clients do
    member do
      post :access_token, :format => :html
    end
  end


  #setting up the api routes
  scope 'v1', :api_call => true, :format => :json do
    get "/feeds/home_timeline",  :to => "home#home_timeline"
    get "/admin/terms_of_service", :to => 'admin#terms_of_service'
    get "/admin/privacy_policy", :to => 'admin#privacy_policy'
    post '/oauth/login_fb',      :to => 'oauth#login_fb',      :as => :login_fb

    resources :users do
      resources :perspectives, :only =>[:index]
      member do
        get :followers
        get :following
        post :follow
        post :unfollow
        get :activity
      end
      collection do
        get :suggested
      end
    end

    resources :perspectives, :only =>[:show]   do
      member do
        post :star
        post :unstar
      end
      collection do
        get :nearby
      end
    end

    resources :places, :except =>[:index] do
      collection do
        get :nearby
        get :random
      end
      resources :perspectives, :except =>[:show] do
        collection do
          resources :photos
          post :update
          delete :destroy
          get :following
          get :all
        end
      end
    end
  end

  match "/:id" => "users#show", :as => :profile


  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
