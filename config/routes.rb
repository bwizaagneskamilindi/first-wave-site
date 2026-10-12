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
  # QR code links open here (organizers only)
  get    "c/:code", to: "organizer/checkins#show",    as: :scan
  post   "c/:code", to: "organizer/checkins#create"
  post "tickets/:code/manual_payment", to: "manual_payments#create", as: :manual_payment
  delete "c/:code", to: "organizer/checkins#destroy"

  namespace :organizer do
  root "dashboard#index"
  get  "checkin",  to: "checkins#index", as: :checkin
  get  "payments", to: "payments#index", as: :payments
  post "payments/:code/confirm", to: "payments#confirm", as: :confirm_payment
  post "payments/:code/reject",  to: "payments#reject",  as: :reject_payment
end

  match "webhooks/momo/:reference", to: "momo_webhooks#update", via:  [ :put, :post ], as: :momo_webhook

  resources :registrations, only: [ :new, :create, :show ]

  get "up" => "rails/health#show", as: :rails_health_check
end
