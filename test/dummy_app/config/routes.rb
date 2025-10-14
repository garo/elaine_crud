Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Root path - shows all resources
  root "libraries#index"

  # CRUD resources - export action is automatically added for ElaineCrud controllers
  resources :libraries
  resources :authors
  resources :books
  resources :book_copies
  resources :tags
  resources :members
  resources :loans
  resources :librarians
  resources :profiles
end
