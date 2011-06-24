class FeaturesController < ApplicationController
  # Get /Features/new
  def new
    @feature = Feature.new
    @feature.heading = Heading.find(params[:parent_id])
  end

  # POST /product_types
  def create
    @feature = Feature.new(params[:feature])

    if @feature.save
      redirect_to('/product_types?id=' + @feature.heading.product_type.id.to_s, :notice => 'URL was successfully created.')
    else
      render :new
    end
    
  end

  # DELETE /features/1
  def destroy
    Feature.find(params[:id]).destroy
    render :nothing=>true
  end

end
