class ScrapingController < ApplicationController
  def index
    # This function shows the application frame and shows a list of the products for a given category.
    if params[:category_id]
      @category_id = params[:category_id]
    else
      @category_id = 29171#20218 # This is hard-coded to be digital cameras from Best Buy's feed
    end
    @product_skus = BestBuyApi.category_ids(@category_id)
  end

  def scrape
    @id = params[:id]
    @raw_info = BestBuyApi.product_search(@id)
    @product_for_display = PP.pretty_print(@raw_info, "")
    @scraped_features = {}
    unless @raw_info.nil?
      rules = ScrapingRule.find_all_by_product_type(Session.product_type)
      rules.each do |r|
        #Find content based on . seperated hierarchical description
        i = r.remote_featurename.split(".")
        c = @raw_info
        i.each {|ii| c = c[ii] unless c.nil?}
        if c
          #Here we would apply Regex
          @scraped_features[r.local_featurename] = c
        end
      end
    end
    render :layout => false
  end

end
