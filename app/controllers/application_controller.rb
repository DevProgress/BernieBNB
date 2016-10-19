class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :require_current_user, :unless => :is_static_page?
  before_action :require_complete_profile, :unless => :is_static_page?
  before_action :set_locale, :unless => :is_static_page?

  helper_method :current_user

  rescue_from ActiveRecord::RecordNotFound do |exception|
    message = "Not found, perhaps it was deleted."
    logger.error message
    if current_user
      redirect_to user_url(current_user), alert: message
    else
      redirect_to root_url, alert: message
    end
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  private

  # Need to check if this is a static page in order to go around the auth checks
  def is_static_page?
    self.class.to_s == "HighVoltage::PagesController"
  end

  def sign_in!(user)
    @current_user = user
    session[:session_token] = user.session_token
  end

  def sign_out!
    current_user.try(:reset_session_token)
    session[:session_token] = nil
  end

  def current_user
    return nil if session[:session_token].nil?
    @current_user ||= User.find_by_session_token(session[:session_token])
  end

  def require_current_user
    if current_user.nil?
      cookies[:redirect_url] = request.fullpath
      redirect_to root_url

    elsif params[:user_id] && current_user.id != params[:user_id].to_i
      redirect_to user_url(current_user)
    end
  end

  def require_complete_profile
    unless current_user.phone && current_user.first_name && current_user.email_confirmed
      redirect_to edit_user_url(current_user)
    end
  end
end
