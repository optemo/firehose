class LayoutEditorController < ApplicationController
  def index
    @product_type = Session.product_type
  end
end
