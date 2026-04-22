Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "sessions#index"

  resources :sessions, only: [:index, :create] do
    collection do
      delete :destroy
    end
  end

  namespace :parent do
    root "dashboard#index"
    resources :profiles, only: [:index, :new, :create, :edit, :update, :destroy]
    resources :global_tasks, except: [:show]
    resources :rewards, only: [:index, :new, :create, :destroy]
    resources :approvals, only: [:index] do
      member do
        patch :approve
        patch :reject
        patch :approve_redemption
        patch :reject_redemption
      end
    end
    resources :activity_logs, only: [:index]
  end

  namespace :kid do
    root to: "dashboard#index"
    resources :missions, only: [] do
      member do
        patch :complete
      end
    end
    resources :rewards, only: [:index] do
      member do
        post :redeem
      end
    end
    resources :wallet, only: [:index]
  end
end
