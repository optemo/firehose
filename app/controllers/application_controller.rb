class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_product_type
  before_filter :set_Session


  def current_product_type
    if session[:current_product_type_id]
      product_type  = ProductType.find_by_id(session[:current_product_type_id])
    else
      product_type = ProductType.first
    end
  end

  def current_product_type=(product_type)
    session[:current_product_type_id] = product_type.try(:id)
  end

  def set_Session
    if params[:product_type] && params[:product_type][:id] 
      Session.new params[:product_type][:id]
    elsif session[:current_product_type_id]
      Session.new session[:current_product_type_id]
    else
      Session.new ProductType.first.id
    end
  end


end
