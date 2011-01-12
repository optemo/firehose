class ApplicationController < ActionController::Base
  protect_from_forgery
  # On each request, set the class variable with the category ID to a global
  # Eventually we will do something with products.yml, have import for multiple categories, and so on.
  before_filter :set_category
  
  def set_category
    ScrapingController.category_id = 21344 # This is for TVs
    # 20218  --  this is all digital cameras
    # 29171  --  this is a small subset (faster scraping & lower load for testing)
  end
end
