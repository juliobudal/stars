Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest"       => "rails/pwa#manifest",       as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"

  resource :family_session,  only: [ :new, :create, :destroy ]
  resource :profile_session, only: [ :new, :create, :destroy ]

  resource :registration, only: [ :new, :create ]
  resource :password_reset, only: [ :new, :create, :edit, :update ]

  get  "invitations/:token/accept" => "invitations#show",   as: :invitation_acceptance
  post "invitations/:token/accept" => "invitations#accept", as: :accept_invitation

  namespace :parent do
    root "dashboard#index"
    get "tasks", to: redirect("/parent/global_tasks")
    resources :invitations, only: [ :new, :create ]
    resources :profiles, only: [ :index, :new, :create, :edit, :update, :destroy ] do
      member do
        patch :reset_pin
        get :manage
        patch :toggle_mission
      end
    end
    resources :global_tasks, except: [ :show ] do
      member do
        patch :toggle_active
        patch :assignment
        post :duplicate
      end
      collection do
        get :assignments
        get :library
        post :add_from_template
      end
    end
    resources :rewards, only: [ :index, :new, :create, :edit, :update, :destroy ] do
      member do
        post :redeem_collective
        post :duplicate
      end
      collection do
        get :library
        post :add_from_template
      end
    end
    resources :categories
    resources :approvals, only: [ :index ] do
      collection do
        post :bulk_approve
        post :bulk_reject
        post :bulk_approve_redemptions
        post :bulk_reject_redemptions
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

    # First-session onboarding tour (gated by KidOnboardingGuard).
    get   "welcome",            to: "onboarding#welcome",         as: :welcome
    get   "welcome/interests",  to: "onboarding#interests",       as: :welcome_interests
    patch "welcome/interests",  to: "onboarding#update_interests"
    get   "welcome/how",        to: "onboarding#how_it_works",    as: :welcome_how
    get   "welcome/ready",      to: "onboarding#ready",           as: :welcome_ready
    post  "welcome/finish",     to: "onboarding#finish",          as: :welcome_finish

    resources :missions, only: %i[new create] do
      member { patch :complete }
    end
    resources :rewards, only: [ :index ] do
      member { post :redeem }
    end
    resources :wallet, only: [ :index ]
    resource :wishlist, only: %i[create destroy], controller: "wishlist"
    resource :interests, only: %i[show update], controller: "interests"

    # Academy module — Pílulas de Conhecimento. See app/models/academy.rb
    # for isolation rules. Trails hold ordered curated lessons; the optional
    # LLM Guia chat is scoped to a lesson.
    namespace :academy do
      root to: "trails#index"
      resources :trails, only: %i[show], param: :slug do
        resources :lessons, only: %i[show], param: :slug do
          member { post :complete }
          resource :guide, only: %i[show create], controller: "guides"
        end
      end
    end
  end

  namespace :parent do
    namespace :academy do
      get "/", to: "dashboard#index", as: :dashboard
    end
  end
end
