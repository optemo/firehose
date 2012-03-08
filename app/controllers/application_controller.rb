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
    if params[:product_type_id]
      Session.new params[:product_type_id]
    else
      Session.new
    end
  end

  def authenticate
    #return true if params[:controller] == 'accessories' || params[:controller] == 'bestbuy' || params[:controller] == 'futureshop'
    return true if request.host == "localhost" #Don't authenticate for development
    authenticate_or_request_with_http_digest(REALM) do |username|
      USERS[username]
    end
  end
end
