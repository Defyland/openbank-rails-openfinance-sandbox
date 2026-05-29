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
      transitioned = consent.revoke!

      if transitioned
        AuditTrail.record!(
          action: "ops.consent.revoked",
          actor: Current.user,
          target: consent,
          metadata: { developer_app_id: consent.developer_app.client_id }
        )
        WebhookDelivery.enqueue!(
          developer_app: consent.developer_app,
          event_type: "consent.revoked",
          aggregate: consent,
          correlation_id: Current.correlation_id,
          payload: {
            event_type: "consent.revoked",
            consent_id: consent.external_id,
            status: consent.status,
            permissions: consent.permissions
          }
        )
      end

      notice = transitioned ? "Consent revoked." : "Consent was already revoked."
      redirect_to ops_consent_path(consent), notice: notice
    end
  end
end
