class CategoryIdProductTypeMapsController < ApplicationController
  # Get /category_ids/new
  def new
    @category = CategoryIdProductTypeMap.new
    @category.product_type = ProductType.find(params[:parent_id])
  end

  # POST /category_ids
  def create
    @category = CategoryIdProductTypeMap.new(params[:category_id_product_type_map])

    @category.save
    redirect_to('/product_types?id=' + @category.product_type.id.to_s, :notice => 'Category ID was successfully created.') 
    
  end

  # DELETE /category_ids/1
  def destroy
    CategoryIdProductTypeMap.find(params[:id]).destroy
    render :nothing => true
  end

end
