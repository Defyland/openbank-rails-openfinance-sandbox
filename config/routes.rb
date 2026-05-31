Rails.application.routes.draw do
  root "ops/dashboard#show"

  get "/up", to: "platform#live"
  get "/ready", to: "platform#ready"
  get "/metrics", to: "platform#metrics"

  resource :session, only: %i[new create destroy]

  namespace :ops do
    root to: "dashboard#show"
    resource :dashboard, only: :show
    resources :developer_apps, only: %i[index show]
    resources :consents, only: %i[index show] do
      patch :revoke, on: :member
    end
    resources :payments, only: %i[index show]
    resources :webhook_deliveries, only: %i[index show] do
      post :replay, on: :member
    end
    resources :scenarios, only: :index do
      patch :activate, on: :member
    end
    resources :audit_events, only: %i[index show]
  end

  namespace :v1 do
    resources :developer_apps, only: :create
    get "/developer_app", to: "developer_apps#show"
    post "/developer_app/client_secret/rotate", to: "developer_apps#rotate_client_secret"
    post "/developer_app/webhook_signing_secret/rotate", to: "developer_apps#rotate_webhook_signing_secret"

    resources :consents, only: %i[index create show] do
      patch :authorize, on: :member
      patch :revoke, on: :member
    end

    post "/oauth/token", to: "tokens#create"

    resources :accounts, only: %i[index show] do
      get :balances, on: :member
      resources :transactions, only: :index, controller: "account_transactions"
    end

    resources :payments, only: %i[index create show]

    resources :webhook_deliveries, only: %i[index show] do
      post :replay, on: :member
    end

    get "/scenarios", to: "scenarios#index"
    patch "/scenarios/:code/activate", to: "scenarios#activate"
  end
end
