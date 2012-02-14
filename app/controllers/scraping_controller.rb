class ScrapingController < ApplicationController
  def index
  end
  
  def datafeed
    @product_skus = BestBuyApi.category_ids(Session.feed_id)
  end

  def scrape
    @id, category = params[:id].split(',') # the patten of params[:id] is product_id,category_id
    candidates, @raw_info = ScrapingRule.scrape(BBproduct.new(:id => @id, :category => category),true)
    render :layout => false
  end
end
