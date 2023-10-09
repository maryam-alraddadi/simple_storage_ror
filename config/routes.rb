Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, path: 'users', only: %i[create]# destroy]
      resources :api_keys, path: 'api-keys', only: %i[index create destroy]
      resources :blobs, path: 'blobs', only: %i[index create show] #destroy]
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
