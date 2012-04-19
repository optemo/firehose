class BBproductsController < ApplicationController  
  def index
    @product_skus = BestBuyApi.category_ids(Session.product_type)
  end

  def show
    @id = params[:id]
    candidates, @raw_info = ScrapingRule.scrape(BBproduct.new(:id => @id, :category => nil),true).last
    render :layout => false
  end
end
