Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  # Example of regular route:

  get 'admin' => 'admin#index', as: :admin_index
  get 'admin/messages' => 'admin#messages', as: :admin_messages
  get 'admin/trades' => 'admin#trades', as: :admin_trades
  post 'admin/push' => 'admin#push', as: :admin_push
  get 'admin/devices' => 'admin#devices', as: :admin_devices
  get 'trades_history' => 'trades#history', as: :history
  get 'performance' => 'trades#performance', as: :performance
  get 'legal' => 'welcome#legal', as: :legal

  resources :trades

  post 'register_token/:token' => 'push_token#register_token', as: :register_token
  post 'clear_badge_count/:token' => 'push_token#clear_badge_count', as: :clear_badge_count

  resources :messages

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
