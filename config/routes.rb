Chatham::Application.routes.draw do

  root :to => "home#index"

  devise_for :users

  match '/oauth/test_request',  :to => 'oauth#test_request',  :as => :test_request
  match '/oauth/token',         :to => 'oauth#token',         :as => :token
  match '/oauth/access_token',  :to => 'oauth#access_token',  :as => :access_token
  match '/oauth/request_token', :to => 'oauth#request_token', :as => :request_token
  match '/oauth/authorize',     :to => 'oauth#authorize',     :as => :authorize
  match '/oauth',               :to => 'oauth#index',         :as => :oauth

  resources :users do
    get :perspectives, :on=>:member
  end

  resources :places do
    collection do
      get :nearby
    end
  end

  resources :perspectives

  resources :oauth_clients# first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
    scope "/v1" do# Keep in mind you can assign values other than :controller and :action
      #resources :users, :format => "json"
      #resources :perspectives, :format => "json"# Sample of named route:
      #resources :places, :format => "json"#   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
      #match '/places/nearby_places',  :to => 'places#nearby_places', :format => "json"# This route can be invoked with purchase_url(:id => product.id)
    end

    match "/:id" => "users#show", :as => :profile

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

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
