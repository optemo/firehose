class ProductTypesController < ApplicationController
  def index
    @product_types = ProductType.find(:all, :include=>[:product_type_headings, :product_type_features])
  end
end
