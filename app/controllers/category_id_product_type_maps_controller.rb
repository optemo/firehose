class CategoryIdProductTypeMapsController < ApplicationController
  # Get /category_ids/new
  def new
    @nodes = BestBuyApi.get_subcategories(params[:id])
    product_type = params[:product_type]
    unless product_type.nil?
      @categories = CategoryIdProductTypeMap.find_all_by_product_type_id(product_type)
    end
    respond_to do |format|
      format.html { render :layout => 'empty' }
    end
  end

  # POST /category_ids
  # FIXME: get rid of this? not used
  # def create
  #   @category = CategoryIdProductTypeMap.new(params[:category_id_product_type_map])
  #   if @category.save
  #     redirect_to('/product_types?id=' + @category.product_type.id.to_s, :notice => 'Category ID was successfully created.')
  #   else
  #     redirect_to('/product_types?id=' + @category.product_type.id.to_s, :notice => 'Category ID creation failed')
  #   end
  # end
  
  def show
    render :nothing => true
  end

  # DELETE /category_ids/1
  def destroy
    CategoryIdProductTypeMap.find(params[:id]).destroy
    render :nothing => true
  end

end
