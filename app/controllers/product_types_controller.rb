class ProductTypesController < ApplicationController
  def index
    @product_types = ProductType.find(:all, :include=>[:headings, :features], :order=>"product_types.id, headings.id, features.id")
    @select_product_types = @product_types
    if !params[:id].blank?
      @select_product_types = [ProductType.find(params[:id], :include=>[:headings, :features], :order=>"product_types.id, headings.id, features.id")]
      @slt = params[:id]
    end
  end

  def show
    @product_types = ProductType.find(:all, :include=>[:headings, :features], :order=>"product_types.id, headings.id, features.id")
    @select_product_types = [ProductType.find(params[:id], :include=>[:headings, :features], :order=>"product_types.id, headings.id, features.id")]
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
      new_value = arr_data.join(',')
    end

    data[names[1]] = new_value
    data.save
    render :inline=>params[:value]
    
  end
end
