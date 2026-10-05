Rails.application.routes.draw do
  root "pages#home"

  get  "register",        to: "registrations#new",    as: :new_registration
  post "register",        to: "registrations#create", as: :registrations
  get  "register/review", to: "registrations#review", as: :review_registration
  get "tickets/:code", to: "registrations#show", as: :ticket
  post "register/confirm", to: "registrations#confirm", as: :confirm_registration
  get  "tickets/:code/pay",                  to: "payments#new",      as: :new_payment
  post "tickets/:code/pay",                  to: "payments#create"
  get  "payments/:reference",                to: "payments#show",     as: :payment
  post "payments/:reference/simulate/:outcome", to: "payments#simulate", as: :simulate_payment

  match "webhooks/momo/:reference", to: "momo_webhooks#update", via: [:put, :post], as: :momo_webhook

  resources :registrations, only: [ :new, :create, :show ]

  get "up" => "rails/health#show", as: :rails_health_check
end
