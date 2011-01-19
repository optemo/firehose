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
    candidates, @raw_info = ScrapingRule.scrape(@id,true)
    @scraped_features = Candidate.organize(candidates).first
    render :layout => false
  end
  
  def rules
    products = BestBuyApi.listing(Session.category_id)
    @exists_count = products["total"]
    @product_count = [20,@exists_count].min
    @rules, @multirules, @colors = Candidate.organize(ScrapingRule.scrape(products["products"].map{|p|p["sku"]}))
  end
end
