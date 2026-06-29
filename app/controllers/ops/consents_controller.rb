module Ops
  class ConsentsController < BaseController
    def index
      @status = params[:status].presence
      @consents = Consent.includes(:developer_app, :sandbox_customer).order(created_at: :desc)
      @consents = @consents.where(status: @status) if @status.present?
    end

    def show
      @consent = Consent.includes(:developer_app, :sandbox_customer, :access_tokens).find(params[:id])
      @payments = @consent.payment_initiations.includes(:account).order(created_at: :desc).limit(20)
    end

    def revoke
      consent = Consent.find(params[:id])
      transitioned = Sandbox::ConsentLifecycle.revoke!(
        consent: consent,
        actor: Current.user,
        audit_action: "ops.consent.revoked",
        correlation_id: Current.correlation_id,
        revocation_reason: "operator_action",
        audit_metadata: { developer_app_id: consent.developer_app.client_id }
      )

      notice = transitioned ? "Consent revoked." : "Consent was already revoked."
      redirect_to ops_consent_path(consent), notice: notice
    end
  end
end
