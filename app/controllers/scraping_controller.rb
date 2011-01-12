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
    @product_count = products["total"]
    @limited_products = [20,@product_count].min
    @rules = ScrapingRule.scrape(products["products"].map{|p|p["sku"]})
    @rules.each do |n,r| # n is the rule name, r is a hash with remote_featurename => {products => ..., rule => ...}
      # For each local feature, we want to build up a list of products that are touched by one or more rules.
      # This becomes the overall coverage, with the 
      # One easy way to do this is with a hash whose keys are the skus.
      sku_hash = {}
      r.each_pair do |rf, data_arr|
        # data_arr is now an array with hashes in priority order.
        data_arr.each do |data|
          data["products"].each{|p|sku_hash[p[0]] = 1 unless p[1].blank?}
          data["products"] = data["products"].sort # so that blanks come out on top?
        end
      end
      # Put the coverage in a variable that we can get out in the view.
      @rules[n]["coverage"] = sku_hash.keys.length
    end
    #@rules = ScrapingRule.find_all_by_product_type(Session.current.product_type).group_by(&:local_featurename)
  end
end
