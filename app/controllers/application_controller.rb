class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_Session

  def set_Session
    #debugger
    if params[:p_type] 
      Session.new params[:p_type]
      session[:current_product_type_id] = params[:p_type] #Save as cookie
    elsif session[:current_product_type_id] #Load from cookie if present
      Session.new session[:current_product_type_id]
    else
      Session.new ProductType.first.id
    end
  end
  
  
end
