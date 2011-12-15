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
    @product_type = ProductType.new(params[:product_type])
    respond_to do |format|
      if @product_type.save
        format.html { redirect_to("/product_types?id=" + @product_type.id.to_s, :notice => 'Product type was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
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
    succeeded = ProductType.find(params[:id]).update_attributes(params[:product_type].reject{|k,v|v.blank?})
    render :inline=>params[:product_type]
  end
end
