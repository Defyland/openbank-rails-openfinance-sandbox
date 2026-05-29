module Sandbox
  class PaymentInitiator
    def self.call!(developer_app:, access_token:, params:, idempotency_key:, correlation_id:)
      raise ActionController::ParameterMissing, "Idempotency-Key" if idempotency_key.blank?

      account = Account.find_by!(external_id: params.fetch(:account_id))
      Security::Authorizer.require_consent_customer!(account, access_token.consent)

      fingerprint = fingerprint_for(params)
      existing = PaymentInitiation.find_by(developer_app: developer_app, idempotency_key: idempotency_key)
      return existing if existing.present? && existing.request_fingerprint == fingerprint
      raise ActiveRecord::RecordNotUnique, "idempotency key reused with a different payload" if existing.present?

      PaymentInitiation.transaction do
        status, failure_code = decision_for(developer_app)
        payment = PaymentInitiation.create!(
          developer_app: developer_app,
          consent: access_token.consent,
          account: account,
          external_reference: params.fetch(:external_reference),
          idempotency_key: idempotency_key,
          request_fingerprint: fingerprint,
          status: status,
          amount_cents: params.fetch(:amount_cents),
          currency: params.fetch(:currency, "BRL"),
          creditor_name: params.fetch(:creditor_name),
          creditor_document: params.fetch(:creditor_document),
          creditor_account: params.fetch(:creditor_account),
          failure_code: failure_code,
          correlation_id: correlation_id,
          processed_at: Time.current,
          metadata: params.fetch(:metadata, {})
        )

        persist_ledger_effect!(account, payment) if payment.accepted?
        enqueue_webhook!(developer_app, payment, correlation_id)
        payment
      end
    end

    def self.fingerprint_for(params)
      canonical = params.deep_stringify_keys.sort.to_h
      OpenSSL::Digest::SHA256.hexdigest(JSON.generate(canonical))
    end

    def self.decision_for(developer_app)
      if ScenarioRegistry.payment_rejected?(developer_app.active_scenario_code)
        [ "rejected", ScenarioRegistry.failure_code(developer_app.active_scenario_code) ]
      else
        [ "accepted", nil ]
      end
    end

    def self.persist_ledger_effect!(account, payment)
      account.debit!(payment.amount_cents)
      LedgerTransaction.create!(
        account: account,
        transaction_type: "debit",
        amount_cents: payment.amount_cents,
        currency: payment.currency,
        description: "Sandbox payment #{payment.external_reference}",
        category: "payment",
        metadata: { payment_id: payment.external_id }
      )
    rescue InsufficientFundsError
      payment.update!(status: "rejected", failure_code: "INSUFFICIENT_FUNDS")
    end

    def self.enqueue_webhook!(developer_app, payment, correlation_id)
      event_type = payment.accepted? ? "payment.accepted" : "payment.rejected"
      WebhookDelivery.enqueue!(
        developer_app: developer_app,
        event_type: event_type,
        aggregate: payment,
        correlation_id: correlation_id,
        payload: {
          event_type: event_type,
          payment_id: payment.external_id,
          status: payment.status,
          amount_cents: payment.amount_cents,
          currency: payment.currency,
          failure_code: payment.failure_code
        }.compact
      )
    end
  end
end
