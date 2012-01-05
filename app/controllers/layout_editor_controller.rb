class LayoutEditorController < ApplicationController
  def index
    pid = Session.product_type_id
    respond_to do |format|
      format.html { redirect_to :action => 'show', :id => pid }
    end
  end
  
  def show
    id = params[:id]
    @product_type = ProductType.find(params[:id])
    @filters = Facet.find_all_by_product_type_id_and_used_for(id, 'filter')
    @sortby = Facet.find_all_by_product_type_id_and_used_for(id, 'sortby')
    @compare = Facet.find_all_by_product_type_id_and_used_for(id, 'show')
  end

  def create
  end

  def update
  end
end
