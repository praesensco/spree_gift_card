Spree::Core::Engine.routes.draw do
  resources :gift_cards do
    member do
      get :redeem
    end
  end
  get 'gift-card' => 'gift_cards#new', as: 'gift-card-new'
  get 'e-gift-card' => 'gift_cards#new', as: 'e-gift-card-new'

  resources :orders do
    patch :apply_gift_card
  end

  namespace :admin do
    resources :gift_cards do
      collection do
        get 'new-classic' => 'gift_cards#new', as: 'gift-card-new'
        get 'new-digital' => 'gift_cards#new', as: 'e-gift-card-new'
      end
    end
  end
end
