class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_Session
  before_filter :authenticate
  before_filter :set_locale
  
  REALM = "Firehose"
  USERS = { Firehose::Application::ACCESS_UNAME => 
          Digest::MD5.hexdigest([Firehose::Application::ACCESS_UNAME, REALM, Firehose::Application::ACCESS_PASSWORD].join(":")) }

  private
  
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
  
  def set_Session
    if params[:product_type]
      Session.new params[:product_type]
      session[:current_product_type] = params[:product_type] #Save as cookie
    elsif session[:current_product_type] #Load from cookie if present
      Session.new session[:current_product_type]
    else
      default_type = ProductCategory.first.product_type
      Session.new default_type
      session[:current_product_type] = default_type
    end
  end

  def authenticate
    authenticate_or_request_with_http_digest(REALM) do |username|
      USERS[username]

    end
  end
end
