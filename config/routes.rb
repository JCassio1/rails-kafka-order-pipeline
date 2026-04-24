Rails.application.routes.draw do
  resources :marketplace_events, only: [:index]
  root "marketplace_events#index"
end
