class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_Session

  def set_Session
    if params[:product_type] && params[:product_type][:id] 
      Session.new params[:product_type][:id]
      session[:current_product_type_id] = params[:product_type][:id] #Save as cookie
    elsif session[:current_product_type_id] #Load from cookie if present
      Session.new session[:current_product_type_id]
    else
      Session.new ProductType.first.id
    end
  end
end
