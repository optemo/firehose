class ApplicationController < ActionController::Base
  require 'net/http'
  protect_from_forgery
  before_filter :set_session
  
  def set_session
    Session.new(request.domain(4) || request.env["REMOTE_HOST"])
  end
end
