class BBproductsController < ApplicationController  
  def index
    @product_skus = BestBuyApi.category_ids(Session.feed_id)
  end

  def show
    @id = params[:id]
    candidates, @raw_info = ScrapingRule.scrape(BBproduct.new(:id => @id, :category => nil),true)
    render :layout => false
  end
end
