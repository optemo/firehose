class HeadingsController < ApplicationController
  # Get /urls/new
  def new
    @heading = Heading.new
    @heading.product_type = ProductType.find(params[:parent_id])
  end

  # POST /product_types
  def create
    @heading = Heading.new(params[:heading])

    if @heading.save
      redirect_to('/product_types?id=' + @heading.product_type.id.to_s, :notice => 'URL was successfully created.')
    else
      render :new
    end
    
  end
  # DELETE /headings/1
  def destroy
    Heading.find(params[:id]).destroy
    render :nothing => true
  end

end
