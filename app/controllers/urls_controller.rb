class UrlsController < ApplicationController
  # Get /urls/new
  def new
    @purl = Url.new
    @purl.product_type = ProductType.find(params[:parent_id])
  end

  # POST /product_types
  def create
    @purl = Url.new(params[:url])

    @purl.save
    redirect_to('/product_types?id=' + @purl.product_type.id.to_s, :notice => 'URL was successfully created.') 
    
  end

  # DELETE /headings/1
  def destroy
    Url.find(params[:id]).destroy
    render :nothing => true
  end

end
