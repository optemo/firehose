class ScrapingController < ApplicationController
  def index
    # This function shows the application frame and shows a list of the products for a given category.
    if params[:category_id]
      @category_id = params[:category_id]
    else
      @category_id = 20218 # This is hard-coded to be digital cameras from Best Buy's feed
    end
    @product_skus = BestBuyApi.category_ids(@category_id)
  end

  def scrape
    @id = params[:id]
    @product = BestBuyApi.product_search(@id)
    @product_for_display = PP.pp(@product, "")
    render :layout => false
  end

end
