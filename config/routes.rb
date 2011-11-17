Firehose::Application.routes.draw do
  
#  get "scraping/index"

#  get "scraping/scrape"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'

  #resources :scraping
  #resources :scraping, :only => [:create], :as => "scraping_rules"
  resources :scraping_rules, :scraping_corrections, :except => [:show, :index]
  resources :results, :product_types
  resources :category_id_product_type_maps, :path=>"category_ids"
  resources :urls, :headings, :features
  

  match 'results/commit/:id' => 'results#commit'
  match 'scrape/:id' => 'scraping#scrape'
  match "rules" => "scraping#rules"
  match "datafeed" => "scraping#datafeed"
  match "scraping_rules/raisepriority" => "scraping_rules#raisepriority"
  match "featured" => "featured#index"



  root :to => "scraping#index"
end
