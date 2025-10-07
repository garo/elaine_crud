Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Root path - shows all resources
  root "libraries#index"

  # CRUD resources
  resources :libraries
  resources :authors
  resources :books
  resources :members
  resources :loans
  resources :librarians
end
