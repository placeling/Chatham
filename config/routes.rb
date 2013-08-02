require 'resque/server'
require 'subdomain'

Chatham::Application.routes.draw do
  get '/escape_pod', to: 'home#escape_pod', as: :escape_pod

  devise_for :users, :controllers => {:sessions => 'sessions', :registrations => :registrations, :confirmations => :confirmations}

  match '/auth/:provider/callback' => 'authentications#create'
  match '/auth/:provider/add' => 'authentications#add'
  match '/auth/:provider/login' => 'authentications#login'

  #setting up the api routes
  scope 'v1', :format => "html"  do
    match "*path" => "home#error503"
  end

  scope 'oauth', :format => "html"  do
    match "*path" => "home#error503"
  end

  if Rails.env.development?
    mount Notifier::Preview => 'mail_view'
  end

  mount Resque::Server, :at => "/resque"

  match '/503', :to => "home#error503"
  root :to => "home#index"
  match "*path" => redirect("/")


end
