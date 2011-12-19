class ProductTypesController < ApplicationController
  def index
    @select_product_types = nil
    unless params[:product_type].blank?
      @select_product_types = [ProductType.find(params[:product_type], :order=>"product_types.id")]
      @slt = params[:product_type]
      # FIXME: since there is usually only one product selected, replace the array with one product
      @product_type = ProductType.find(params[:product_type])
      @categories = CategoryIdProductTypeMap.find_all_by_product_type_id(params[:product_type])
    end
    
    respond_to do |format|
      if params[:ajax] == 'true'
        format.html { render :layout => 'ajax' }
      else
        format.html
      end
    end
  end

  def show
    @product_types = ProductType.find(:all, :order=>"product_types.id")
    @select_product_types = [ProductType.find(params[:product_type], :order=>"product_types.id")]
    @slt = params[:product_type]
    render :index
  end
  
  # GET /product_types/new
  def new
    if params[:new_type].nil?
      @product_type = ProductType.new
    end
  end
  
  def update_categories(categories, pid)
    unless categories.nil?
      categories.each do |element|
       pair = element.last
       catid, catname = pair.first, pair.last
       category = CategoryIdProductTypeMap.new(:product_type_id => pid, :category_id => catid, :name => catname)
       # TODO: report error if it can't be saved
       category.save()
      end
    end
  end
  

  # POST /product_types
  def create
    @product_type = ProductType.new(:name => params[:name])
    @product_type.save()
    update_categories(params[:categories], @product_type.id)
    
    @view_path = "/product_types?product_type=" + @product_type.id.to_s

    respond_to do |format|
      format.html { render :partial => "redirecting" }
    end
  end
  
  def update    
    @past_categories = CategoryIdProductTypeMap.find_all_by_product_type_id(params[:id])
    @past_categories.each {|c| c.destroy}
    update_categories(params[:categories], params[:id])
    @view_path = "/product_types?product_type=" + params[:id]

    respond_to do |format|
      format.html { render :partial => "redirecting" }
    end
  end
  
  def edit
    @product_type = ProductType.find(params[:id])
    @categories = CategoryIdProductTypeMap.find_all_by_product_type_id(params[:id])
  end

  def destroy
    @product_type = ProductType.find(params[:id])
    if @product_type.destroy
      respond_to do |format|
        format.html { redirect_to product_types_url(nil, :ajax => true) }
      end
    else
      render :nothing => true
    end
  end
end
