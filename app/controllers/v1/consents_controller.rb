module V1
  class ConsentsController < ApiController
    before_action :authenticate_client!

    def index
      consents = current_developer_app.consents.includes(:sandbox_customer).order(created_at: :desc)
      render json: { consents: consents.map { |consent| ApiSerializer.consent(consent) } }
    end

    def create
      consent = Sandbox::ConsentCreator.call!(
        developer_app: current_developer_app,
        params: consent_params.to_h.symbolize_keys,
        correlation_id: Current.correlation_id
      )
      AuditTrail.record!(
        action: "v1.consent.created",
        actor: current_developer_app,
        target: consent,
        metadata: {
          permissions: consent.permissions,
          sandbox_customer_id: consent.sandbox_customer.external_id
        }
      )
      render json: { consent: ApiSerializer.consent(consent) }, status: :created
    end

    def show
      render json: { consent: ApiSerializer.consent(find_consent) }
    end

    def authorize
      consent = find_consent

      Sandbox::ConsentLifecycle.authorize!(
        consent: consent,
        actor: current_developer_app,
        audit_action: "v1.consent.authorized",
        correlation_id: Current.correlation_id
      )

      render json: { consent: ApiSerializer.consent(consent) }
    end

    def revoke
      consent = find_consent

      Sandbox::ConsentLifecycle.revoke!(
        consent: consent,
        actor: current_developer_app,
        audit_action: "v1.consent.revoked",
        correlation_id: Current.correlation_id,
        revocation_reason: "partner_request"
      )

      render json: { consent: ApiSerializer.consent(consent) }
    end

    private

    def find_consent
      current_developer_app.consents.includes(:sandbox_customer).find_by!(external_id: params[:id])
    end

    def consent_params
      params.require(:consent).permit(:customer_document_number, :external_id, :expires_at, permissions: [], metadata: {})
    end
  end
end
