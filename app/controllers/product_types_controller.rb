class ProductTypesController < ApplicationController
  def index
    @product_types = ProductType.find(:all, :order=>"product_types.id")
    @select_product_types = @product_types
    if !params[:id].blank?
      @select_product_types = [ProductType.find(params[:id], :order=>"product_types.id")]
      @slt = params[:id]
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
    @select_product_types = [ProductType.find(params[:id], :order=>"product_types.id")]
    @slt = params[:id]
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
    # TODO: remove this object from Session.product_type
    # display a 'success' message, 
    # and check that the product type doesn't actually appear anywhere
    if @product_type.destroy
      #redirect_to :action => index
      #render :index
      respond_to do |format|
        #render :index
        format.html { redirect_to product_types_url(nil, :ajax => true) }
      end
    else
      render :nothing
    end
  end


  def update
    data = nil
    names = params[:name].split('-')
    if names[0] == "product_type"
      data = ProductType.find(params[:dId])
    end
    if names[0] == "url"
      data = Url.find(params[:dId])
    end
    if names[0] == "heading"
      data = Heading.find(params[:dId])
    end
    if names[0] == "feature"
      data = Feature.find(params[:dId])
    end
    if names[0] == "category_id_product_type_maps"
      data = CategoryIdProductTypeMap.find(params[:dId])
    end


    new_value = params[:value]
    if params[:orgElement]
      arr_data = data[names[1]].split(',')

      arr_data.delete_if{|x| x.strip.blank?}      
      if params[:value].empty?
        arr_data.delete_if { |x| x.strip == params[:orgElement].strip }
      else
        index = arr_data.index{ |x| x.strip == params[:orgElement].strip }
        arr_data[index] = params[:value]
      end
      new_value = arr_data.map{|d| d=d.strip}.join(',')
    end

    data[names[1]] = new_value
    data.save
    render :inline=>params[:value]
    
  end
end
