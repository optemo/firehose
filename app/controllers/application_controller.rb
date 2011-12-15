class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_Session
  before_filter :authenticate
  
  REALM = "Firehose"
  USERS = { Firehose::Application::ACCESS_UNAME => 
          Digest::MD5.hexdigest([Firehose::Application::ACCESS_UNAME, REALM, Firehose::Application::ACCESS_PASSWORD].join(":")) }

  private
  
  def set_Session
    if params[:product_type] 
      Session.new params[:product_type]
      session[:current_product_type_id] = params[:product_type] #Save as cookie
    elsif session[:current_product_type_id] #Load from cookie if present
      Session.new session[:current_product_type_id]
    else
      Session.new ProductType.first.id
    end
  end

  def authenticate
    authenticate_or_request_with_http_digest(REALM) do |username|
      USERS[username]
    end
  end
end
