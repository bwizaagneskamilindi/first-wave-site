Rails.application.routes.draw do
  root "pages#home"

  get  "register",        to: "registrations#new",    as: :new_registration
  post "register",        to: "registrations#create", as: :registrations
  get  "register/review", to: "registrations#review", as: :review_registration

  get "up" => "rails/health#show", as: :rails_health_check
end
