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
      previous_status = consent.status
      active_tokens_count = consent.access_tokens.where(revoked_at: nil).count
      transitioned = consent.revoke!

      if transitioned
        AuditTrail.record!(
          action: "ops.consent.revoked",
          actor: Current.user,
          target: consent,
          metadata: { developer_app_id: consent.developer_app.client_id }
        )
        event_id = WebhookDelivery.generate_event_id
        WebhookDelivery.enqueue!(
          developer_app: consent.developer_app,
          event_type: "consent.revoked",
          aggregate: consent,
          correlation_id: Current.correlation_id,
          event_id: event_id,
          payload: Sandbox::PartnerEvent.consent_revoked(
            consent: consent,
            event_id: event_id,
            correlation_id: Current.correlation_id,
            revocation_reason: "operator_action",
            previous_status: previous_status,
            tokens_revoked: active_tokens_count
          )
        )
      end

      notice = transitioned ? "Consent revoked." : "Consent was already revoked."
      redirect_to ops_consent_path(consent), notice: notice
    end
  end
end
