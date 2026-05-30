module V1
  class PaymentsController < ApiController
    before_action -> { authenticate_token!("PAYMENTS_INITIATE") }

    def index
      payments = current_developer_app.payment_initiations.where(consent: current_consent).order(created_at: :desc)
      render json: { payments: payments.map { |payment| ApiSerializer.payment(payment) } }
    end

    def create
      payment = Sandbox::PaymentInitiator.call!(
        developer_app: current_developer_app,
        access_token: Current.access_token,
        params: payment_params,
        idempotency_key: request.headers["Idempotency-Key"],
        correlation_id: Current.correlation_id
      )

      if payment.created_by_request?
        AuditTrail.record!(
          action: "v1.payment.created",
          actor: current_developer_app,
          target: payment,
          metadata: {
            status: payment.status,
            amount_cents: payment.amount_cents,
            consent_id: payment.consent.external_id
          }
        )
      end

      render json: { payment: ApiSerializer.payment(payment) }, status: payment.created_by_request? ? :created : :ok
    end

    def show
      payment = current_developer_app.payment_initiations.where(consent: current_consent).find_by!(external_id: params[:id])
      render json: { payment: ApiSerializer.payment(payment) }
    end

    private

    def payment_params
      payment = params.require(:payment)
      {
        account_id: payment.require(:account_id),
        external_reference: payment.require(:external_reference),
        amount_cents: payment.require(:amount_cents),
        currency: payment.fetch(:currency, "BRL"),
        creditor_name: payment.require(:creditor_name),
        creditor_document: payment.require(:creditor_document),
        creditor_account: payment.require(:creditor_account)
      }
    end
  end
end
