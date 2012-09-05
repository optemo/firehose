class BBproductsController < ApplicationController  
  def index
    @product_skus = BestBuyApi.category_ids(Session.product_type)
  end

  def show
    @id = params[:id]
    @raw_info = ScrapingRule.scrape(BBproduct.new(:id => @id, :category => nil),true)[:raw]
    render :layout => false
  end
end
