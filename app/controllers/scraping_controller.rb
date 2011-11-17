class ScrapingController < ApplicationController
  def index
    if params[:product_type]
      self.current_product_type = ProductType.find params[:product_type][:id]
    end
    @product_type = self.current_product_type
    Session.new @product_type.id
  end
  
  def datafeed
    # This function shows the application frame and shows a list of the products for a given category.
    if params[:category_id]
      Session.category_id = params[:category_id]
    end
    @product_skus = BestBuyApi.category_ids(Session.category_id)
  end

  def scrape
    require 'ruby-debug' #Used for pretty print PP
    ids = params[:id].split(',') # the patten of params[:id] is product_id,category_id
    @id = ids[0]
    candidates, @raw_info = ScrapingRule.scrape(BBproduct.new(:id => @id, :category => ids[1]),true)
    @scraped_features = Candidate.organize(candidates).first
    render :layout => false
  end
  
  def rules
    products,@exists_count = BestBuyApi.some_ids(Session.category_id)
    @product_count = products.count
    @rules, @multirules, @colors = Candidate.organize(ScrapingRule.scrape(products))
    if (newcount = @rules.values.first.first.count) < @product_count
      @warning = "#{@product_count-newcount} product#{'s' if @product_count-newcount > 1} missing"
      @product_count = newcount
    end
  end
end
