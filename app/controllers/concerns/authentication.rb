module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    resume_session.present?
  end

  def current_user
    Current.user
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    return Current.session if Current.session.present?

    session_record = Session.includes(:user).find_by(id: cookies.signed[:session_id])
    return if session_record.nil?

    if session_record.stale?
      session_record.destroy
      cookies.delete(:session_id)
      return
    end

    Current.session = session_record.refresh_if_needed!
    Current.user = Current.session&.user
    Current.session
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.fullpath
    redirect_to new_session_path
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || ops_root_path
  end

  def start_new_session_for(user)
    return_to_after_authenticating = session[:return_to_after_authenticating]
    reset_session
    session[:return_to_after_authenticating] = return_to_after_authenticating if return_to_after_authenticating.present?

    user.sessions.create!(
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    ).tap do |session_record|
      Current.session = session_record
      Current.user = user
      cookies.signed.permanent[:session_id] = {
        value: session_record.id,
        httponly: true,
        same_site: :lax,
        secure: Rails.env.production?
      }
    end
  end

  def terminate_session
    Current.session&.destroy
    reset_session
    Current.session = nil
    Current.user = nil
    cookies.delete(:session_id)
  end
end
