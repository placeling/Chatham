Chatham::Application.routes.draw do

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
      get :followees
      post :follow
      post :unfollow
    end
    collection do
      get :suggested
    end
  end

  resources :perspectives, :only =>:show

  resources :places do
    collection do
      get :nearby
    end
    resources :perspectives, :except =>[:show, :index] do
      collection do
        post :update
        get :edit
      end
    end
  end

  #this one is used to post a perspective when client has a google_id but not a place_id
  match '/places/perspectives/' => 'perspectives#create', :as => 'places_perspectives'

  resources :oauth_clients do
    member do
      post :access_token, :format => :html
    end
  end

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'

  #setting up the api routes
  scope 'v1', :api_call => true, :format => :json do
    resources :users do
      resources :perspectives, :only =>[:index]
      member do
        get :followers
        get :followees
        post :follow
        post :unfollow
      end
      collection do
        get :suggested
      end
    end
    resources :perspectives, :only =>:show

    resources :places do
      collection do
        get :nearby
      end
      resources :perspectives, :except =>[:show, :index] do
        collection do
          post :update
          get :edit
        end
      end
    end

    #this one is used to post a perspective when client has a google_id but not a place_id
    match '/v1/places/perspectives/' => 'perspectives#create', :as => 'v1_places_perspectives'
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
