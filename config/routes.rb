Spree::Core::Engine.routes.draw do
  resources :gift_cards do
    member do
      get :redeem
    end
  end

  resources :orders do
    patch :apply_gift_card
  end

  namespace :admin do
    resources :gift_cards
  end
end
