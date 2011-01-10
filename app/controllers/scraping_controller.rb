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
    @limited_products = [20,@product_count].min
    @rules = ScrapingRule.scrape(products["products"].map{|p|p["sku"]})
    @rules.each do |n,r| # n is the rule name, r is a hash with remote_featurename => {products => ..., rule => ...}
      # For each local feature, we want to build up a list of products that are touched by one or more rules.
      # This becomes the overall coverage, with the 
      # One easy way to do this is with a hash whose keys are the skus.
      ordered_rules = ScrapingRule.rules_by_priority(r)
      sku_hash = {}
      ordered_rules.each do |o|
        o[1]["products"].each{|p|sku_hash[p[0]] = 1}
        o[1]["products"] = o[1]["products"].sort
      end
      @rules[n]["ordered"] = ordered_rules
      # Put the coverage in a variable that we can get out in the view.
      @rules[n]["coverage"] = sku_hash.keys.length
    end
    #@rules = ScrapingRule.find_all_by_product_type(Session.product_type).group_by(&:local_featurename)
  end
end
