class ProductTypesController < ApplicationController
  def index
    if params[:product_type].blank?
      pid = session[:current_product_type_id]
    else
      pid = params[:product_type]
    end
    @product_type = ProductType.find(pid)
    @categories = CategoryIdProductTypeMap.find_all_by_product_type_id(pid)
    
    respond_to do |format|
      if params[:ajax] == 'true'
        # TODO: determine if the ajax layout is necessary here
        format.html { redirect_to :action => 'show', :id => pid, :layout => 'ajax' }
      else
        format.html { redirect_to :action => 'show', :id => pid }
      end
    end
  end

  def show
    @product_type = ProductType.find(params[:id])
    @categories = CategoryIdProductTypeMap.find_all_by_product_type_id(params[:id])
    session[:current_product_type_id] = params[:id]

    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  # GET /product_types/new
  def new
    @product_type = ProductType.new
    debugger
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  def update_categories(in_categories, pid)
    @errors = []
    unless in_categories.nil?
      categories = in_categories.values()
      categories.each do |element|
        catid, catname = element.first, element.last
        category = CategoryIdProductTypeMap.new(:product_type_id => pid, :category_id => catid, :name => catname)
        category.save()
        if (category.errors.any?)
          @errors << category.errors
        end
      end
    end
    return @errors
  end
  
  # POST /product_types
  def create
    @product_type = ProductType.new(:name => params[:name])
    if @product_type.save()
      # there cannot be any errors in adding categories through the new form
      @errors = update_categories(params[:categories], @product_type.id)
      session[:current_product_type_id] = @product_type.id
      respond_to do |format|
          format.html { render :partial => "redirecting" }
      end
    else
      respond_to do |format|
        format.html { render :action => "new" }
      end
    end
  end
  
  def update
    @errors = update_categories(params[:categories], params[:id])
    session[:current_product_type_id] = params[:id]
    
    respond_to do |format|
      unless @errors.length > 0
        format.html { render :partial => "redirecting" }
      else
        @product_type = ProductType.find(params[:id])
        @categories = CategoryIdProductTypeMap.find_all_by_product_type_id(params[:id])
        format.html { render :action => "edit" }
      end
    end
    
  end
  
  def edit
    @product_type = ProductType.find(params[:id])
    @categories = CategoryIdProductTypeMap.find_all_by_product_type_id(params[:id])
  end

  def destroy
    @product_type = ProductType.find(params[:id])
    if @product_type.destroy
      session.delete(:current_product_type_id) if (params[:id] == session[:current_product_type_id])
      respond_to do |format|
        format.html { redirect_to product_types_url }
      end
    else
      render :nothing => true
    end
  end
end
