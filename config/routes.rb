
Chatham::Application.routes.draw do
  post '/escape_pod', to: 'home#escape_pod', as: :escape_pod

  devise_for :users

  match '/auth/:provider/callback' => 'authentications#create'
  match '/auth/:provider/login' => 'authentications#login'

  #setting up the api routes
  scope 'v1', :format => "html"  do
    match "*path" => "home#error503"
  end

  scope 'oauth', :format => "html"  do
    match "*path" => "home#error503"
  end

  match '/503', :to => "home#error503"
  root :to => "home#index"
  match "*path" => redirect("/")


end
