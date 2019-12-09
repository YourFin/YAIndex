Rails.application.routes.draw do
  get 'files/list'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'web_app#main'
  # Route any get requests not explicitly mentioned to serve the webapp
  match '*path', to: 'web_app#main', via: :all
end
