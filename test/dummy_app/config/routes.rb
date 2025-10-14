Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Root path - shows all resources
  root "libraries#index"

  # CRUD resources
  resources :libraries do
    collection { get :export }
  end
  resources :authors do
    collection { get :export }
  end
  resources :books do
    collection { get :export }
  end
  resources :book_copies do
    collection { get :export }
  end
  resources :tags do
    collection { get :export }
  end
  resources :members do
    collection { get :export }
  end
  resources :loans do
    collection { get :export }
  end
  resources :librarians do
    collection { get :export }
  end
  resources :profiles do
    collection { get :export }
  end
end
