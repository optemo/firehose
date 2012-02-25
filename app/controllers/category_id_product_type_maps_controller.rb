class CategoryIdProductTypeMapsController < ApplicationController
  # Get /category_ids/new
  def new
    debugger
    @nodes = BestBuyApi.get_subcategories(params[:id])
    respond_to do |format|
      format.html { render :layout => 'empty' }
    end
  end
  
  def show
    debugger
    render :partial => 'tree'
  end

end
