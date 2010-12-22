class ScrapingController < ApplicationController
  def index
    @category_id = 20218
  end
  
  def datafeed
    # This function shows the application frame and shows a list of the products for a given category.
    if params[:category_id]
      @category_id = params[:category_id]
    else
      @category_id = 20218 #29171 # This is hard-coded to be digital cameras from Best Buy's feed. 29171 is a category with very few items.
    end
    @product_skus = BestBuyApi.category_ids(@category_id)
  end

  def scrape
    @id = params[:id]
    @scraped_features = ScrapingRule.scrape(@id, true)
    @raw_info = @scraped_features.delete("RAW-JSON")
    render :layout => false
  end
  
  def rules
    @category_id = 20218
    products = BestBuyApi.listing(@category_id)
    @product_count = products["total"]
    @limited_products = min(20,@product_count)
    @rules = ScrapingRule.scrape(products["products"].map{|p|p["sku"]})
    #@rules = ScrapingRule.find_all_by_product_type(Session.product_type).group_by(&:local_featurename)
  end

end
