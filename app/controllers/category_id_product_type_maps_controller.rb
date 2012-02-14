class CategoryIdProductTypeMapsController < ApplicationController
  # Get /category_ids/new
  def new
    @nodes = BestBuyApi.get_subcategories(params[:id])
    # product_type = params[:product_type]
    # unless product_type.nil?
    #   @categories = CategoryIdProductTypeMap.find_all_by_product_type_id(product_type)
    # end
    respond_to do |format|
      format.html { render :layout => 'empty' }
    end
  end
  #
  def show
    debugger
    render :nothing => true
  end

  # DELETE /category_ids/1
  def destroy
    CategoryIdProductTypeMap.find(params[:id]).destroy
    render :nothing => true
  end

end
