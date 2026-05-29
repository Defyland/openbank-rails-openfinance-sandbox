class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])

    if user&.authenticate(params[:password])
      start_new_session_for(user)
      AuditTrail.record!(action: "ops.session.created", actor: user, target: user)
      redirect_to after_authentication_url
    else
      AuditTrail.record!(
        action: "ops.session.failed",
        metadata: { email_address: params[:email_address].to_s.downcase }
      )
      redirect_to new_session_path, alert: "Invalid email address or password."
    end
  end

  def destroy
    AuditTrail.record!(action: "ops.session.destroyed", actor: Current.user, target: Current.user)
    terminate_session
    redirect_to new_session_path
  end
end
