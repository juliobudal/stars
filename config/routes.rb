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
      end
    end
    resources :global_tasks, except: [ :show ] do
      member { patch :toggle_active }
    end
    resources :rewards, only: [ :index, :new, :create, :edit, :update, :destroy ] do
      member { post :redeem_collective }
    end
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
    resource :interests, only: %i[show update], controller: "interests"

    # Academy module — see app/models/academy.rb for isolation rules.
    namespace :academy do
      root to: "subjects#index"
      resources :subjects, only: %i[index show], param: :id do
        resources :trails, only: %i[show], param: :id
        resources :missions, only: %i[show], param: :id do
          member { post :advance }
          get "visits/:visit_id", to: "missions#review_visit", as: :review_visit
          resource :guide, only: %i[show create], controller: "guides"
        end
      end
      get "atlas", to: "atlas#index", as: :atlas
      resources :practice_wagers, only: %i[update], path: "apostas"
      # Pílula do Dia — daily 60-90s lens surface.
      # `pill` (singular) shows today's pick; `pills` (plural) lists history;
      # per-id share endpoint records the parent share for that PillView row.
      get  "pill", to: "pills#show", as: :pill
      get  "pills", to: "pills#index", as: :pills
      post "pills/:id/share", to: "pills#share", as: :share_pill

      # Lightning Round — 5 retrieval questions in ≤90s.
      get  "lightning", to: "lightning#show",   as: :lightning
      post "lightning", to: "lightning#answer", as: :lightning_answer

      # Cast gallery — the 5 sub-voices the kid meets across lens types.
      get "cast", to: "cast#index", as: :cast
    end
  end

  namespace :parent do
    namespace :academy do
      get "/", to: "dashboard#index", as: :dashboard
      get "compare", to: "dashboard#compare", as: :compare
      get "library", to: "library#index", as: :library
      resources :practice_wagers, only: %i[update], path: "apostas"
      resources :journeys, only: %i[index]
      resources :cards, only: %i[show], constraints: { format: "svg" }
    end
  end

  namespace :admin do
    namespace :academy do
      resources :missions, only: %i[index show edit update]
      resources :lenses, only: %i[index edit update] do
        member do
          patch :flag
        end
      end
    end
  end
end
