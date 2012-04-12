class CategoryIdProductTypeMapsController < ApplicationController
  layout false
  # Get /category_ids/new
  def new
    @nodes = BestBuyApi.get_subcategories(params[:id])
    respond_to do |format|
      format.html { render :layout => 'empty' }
    end
  end
  
  def show
    render :partial => 'tree'
  end

end