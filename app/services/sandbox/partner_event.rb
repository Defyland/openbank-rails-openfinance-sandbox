module Sandbox
  class PartnerEvent
    PRODUCER = "openbank-sandbox"
    SCHEMA_VERSION = 1

    def self.consent_authorized(consent:, event_id:, correlation_id:)
      envelope(
        event_id: event_id,
        event_type: "consent.authorized",
        developer_app: consent.developer_app,
        consent_id: consent.external_id,
        correlation_id: correlation_id,
        payload: {
          status: "authorized",
          permissions: consent.permissions,
          authorized_at: consent.authorized_at&.iso8601,
          expires_at: consent.expires_at.iso8601,
          customer_reference: {
            external_id: consent.sandbox_customer.external_id,
            segment: consent.sandbox_customer.segment
          }.compact
        }
      )
    end

    def self.consent_revoked(consent:, event_id:, correlation_id:, revocation_reason:, previous_status:, tokens_revoked:)
      envelope(
        event_id: event_id,
        event_type: "consent.revoked",
        developer_app: consent.developer_app,
        consent_id: consent.external_id,
        correlation_id: correlation_id,
        payload: {
          status: "revoked",
          revoked_at: consent.revoked_at&.iso8601,
          revocation_reason: revocation_reason,
          tokens_revoked: tokens_revoked,
          previous_status: previous_status
        }.compact
      )
    end

    def self.payment_created(payment:, event_id:, correlation_id:)
      envelope(
        event_id: event_id,
        event_type: "payment.created",
        developer_app: payment.developer_app,
        consent_id: payment.consent.external_id,
        payment_id: payment.external_id,
        correlation_id: correlation_id,
        payload: {
          status: "created",
          idempotency_key: payment.idempotency_key,
          external_reference: payment.external_reference,
          amount_cents: payment.amount_cents,
          currency: payment.currency,
          debtor_account_id: payment.account.external_id,
          creditor: {
            name: payment.creditor_name,
            document: payment.creditor_document,
            account: payment.creditor_account
          }
        }
      )
    end

    def self.payment_settled(payment:, ledger_transaction:, event_id:, correlation_id:)
      envelope(
        event_id: event_id,
        event_type: "payment.settled",
        developer_app: payment.developer_app,
        consent_id: payment.consent.external_id,
        payment_id: payment.external_id,
        correlation_id: correlation_id,
        payload: {
          status: "settled",
          settled_at: payment.processed_at&.iso8601 || Time.current.iso8601,
          amount_cents: payment.amount_cents,
          currency: payment.currency,
          ledger_effect: {
            debtor_account_id: payment.account.external_id,
            transaction_type: "debit",
            ledger_transaction_id: ledger_transaction&.external_id
          }.compact
        }
      )
    end

    def self.payment_rejected(payment:, event_id:, correlation_id:)
      envelope(
        event_id: event_id,
        event_type: "payment.rejected",
        developer_app: payment.developer_app,
        consent_id: payment.consent.external_id,
        payment_id: payment.external_id,
        correlation_id: correlation_id,
        payload: {
          status: "rejected",
          rejected_at: payment.processed_at&.iso8601 || Time.current.iso8601,
          failure_code: payment.failure_code || "VALIDATION_FAILED",
          amount_cents: payment.amount_cents,
          currency: payment.currency
        }
      )
    end

    def self.envelope(event_id:, event_type:, developer_app:, correlation_id:, payload:, consent_id: nil, payment_id: nil)
      {
        event_id: event_id,
        event_type: event_type,
        schema_version: SCHEMA_VERSION,
        occurred_at: Time.current.iso8601,
        producer: PRODUCER,
        developer_app_id: developer_app.client_id,
        consent_id: consent_id,
        payment_id: payment_id,
        correlation_id: correlation_id,
        payload: payload
      }.compact
    end

    private_class_method :envelope
  end
end
