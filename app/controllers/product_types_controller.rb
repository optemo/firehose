class ProductTypesController < ApplicationController
  def index
    @select_product_types = nil
    unless params[:product_type].blank?
      @select_product_types = [ProductType.find(params[:product_type], :order=>"product_types.id")]
      @slt = params[:product_type]
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

  # POST /product_types
  def create
    @product_type = ProductType.new(:name => params[:name])
    @product_type.save()
    categories = params[:categories]
    unless categories.nil?
      categories.each do |catid|
       category = CategoryIdProductTypeMap.new(:product_type_id => @product_type.id, :category_id => catid)
       category.save()
      end
    end

    respond_to do |format|
      #format.html { redirect_to product_types_url(:product_type => @product_type.id, :ajax => 'true') }
      format.html { redirect_to_show("/product_types?product_type=" + @product_type.id.to_s, :newbool => true) }
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
      render :nothing
    end
  end

  def update
    debugger
    @past_categories = CategoryIdProductTypeMap.find_all_by_product_type_id(params[:id])
    @past_categories.each {|c| c.destroy}
    
    params[:categories].each do |catid|
        category = CategoryIdProductTypeMap.new(:product_type_id => params[:id], :category_id => catid)
        category.save()
    end
    
    render :inline=>params[:product_type]
  end
end
