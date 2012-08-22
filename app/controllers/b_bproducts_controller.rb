require 'remote_util'
class BBproductsController < ApplicationController  
  def index
    RemoteUtil.do_with_retry({max_tries: 15, interval: 3, exceptions: [BestBuyApi::RequestError]}){|is_retry| @product_skus = BestBuyApi.category_ids(Session.product_type)}
  end

  def show
    @id = params[:id]
    @raw_info = ScrapingRule.scrape(BBproduct.new(:id => @id, :category => nil),true)[:raw]
    render :layout => false
  end
end
