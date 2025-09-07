Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :v1 do
    resources :menus do
      resources :menu_items, only: [:index, :create]
    end

    resources :menu_items, except: [:new, :edit]
  end
end
