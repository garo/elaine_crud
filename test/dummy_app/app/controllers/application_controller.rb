class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  #protect_from_forgery with: :exception
  #protect_from_forgery with: :null_session if Rails.env.development?
  skip_before_action :verify_authenticity_token if Rails.env.development?

end
