Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  resource :family_session,  only: [ :new, :create, :destroy ]
  resource :profile_session, only: [ :new, :create, :destroy ]

  resource :registration, only: [ :new, :create ]
  resource :password_reset, only: [ :new, :create, :edit, :update ]

  get  "invitations/:token/accept" => "invitations#show",   as: :invitation_acceptance
  post "invitations/:token/accept" => "invitations#accept", as: :accept_invitation

  namespace :parent do
    root "dashboard#index"
    resources :invitations, only: [ :new, :create ]
    resources :profiles, only: [ :index, :new, :create, :edit, :update, :destroy ] do
      member do
        patch :reset_pin
      end
    end
    resources :global_tasks, except: [ :show ] do
      member { patch :toggle_active }
    end
    resources :rewards, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :categories
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
    resources :missions, only: %i[new create] do
      member { patch :complete }
    end
    resources :rewards, only: [ :index ] do
      member { post :redeem }
    end
    resources :wallet, only: [ :index ]
    resource :wishlist, only: %i[create destroy], controller: "wishlist"
  end
end
