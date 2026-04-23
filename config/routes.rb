Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "sessions#index"

  resources :sessions, only: [ :index, :create ] do
    collection do
      delete :destroy
    end
  end

  resource :registration, only: [ :new, :create ]
  resource :password_reset, only: [ :new, :create, :edit, :update ]

  namespace :parent do
    root "dashboard#index"
    resources :profiles, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :global_tasks, except: [ :show ] do
      member do
        patch :toggle_active
      end
    end
    resources :rewards, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :approvals, only: [ :index ] do
      collection do
        post :bulk_approve
        post :bulk_reject
      end
      member do
        patch :approve
        patch :reject
        patch :approve_redemption
        patch :reject_redemption
      end
    end
    resources :activity_logs, only: [ :index ]
    resource :settings, only: [ :show, :update ]
  end

  namespace :kid do
    root to: "dashboard#index"
    resources :missions, only: [] do
      member do
        patch :complete
      end
    end
    resources :rewards, only: [ :index ] do
      member do
        post :redeem
      end
    end
    resources :wallet, only: [ :index ]
  end
end
