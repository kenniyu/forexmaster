class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


  private
  def authenticate
    authenticate_or_request_with_http_basic("Administration") do |user,pass|
      user == ENV["USERNAME"] && pass = ENV["PASSWORD"]
    end
  end
end
