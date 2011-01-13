class ScrapingController < ApplicationController
  def index
  end
  
  def datafeed
    # This function shows the application frame and shows a list of the products for a given category.
    if params[:category_id]
      Session.category_id = params[:category_id]
    end
    @product_skus = BestBuyApi.category_ids(Session.category_id)
  end

  def scrape
    @id = params[:id]
    @scraped_features = ScrapingRule.scrape(@id, true)
    @raw_info = @scraped_features.delete("RAW-JSON")
    render :layout => false
  end
  
  def rules
    products = BestBuyApi.listing(Session.category_id)
    @product_count = [[20,products["total"]].min,products["total"]]
    @rules = ScrapingRule.scrape(products["products"].map{|p|p["sku"]})
    @rules.each do |n,r| # n is the rule name, r is a hash with remote_featurename => {products => ..., rule => ...}
      # For each local feature, we want to build up a list of products that are touched by one or more rules.
      # This becomes the overall coverage, with the 
      # One easy way to do this is with a hash whose keys are the skus.
      sku_hash = {}
      r.each do |scraped_result|
        scraped_result.products.each{|p|sku_hash[p.id] = 1 unless p.parsed.blank?}
      end
      # Put the coverage in a variable that we can get out in the view.
      @rules[n].unshift sku_hash.keys.length
    end
  end
end
