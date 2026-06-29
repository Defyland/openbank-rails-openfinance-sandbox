module Sandbox
  class ConsentLifecycle
    def self.authorize!(consent:, actor:, audit_action:, correlation_id:)
      ActiveRecord::Base.transaction do
        previous_status = consent.status
        transitioned = consent.authorize!

        if transitioned
          AuditTrail.record!(
            action: audit_action,
            actor: actor,
            target: consent,
            metadata: { from: previous_status, to: consent.status }
          )
          enqueue_authorized_webhook!(consent:, correlation_id:)
        end

        transitioned
      end
    end

    def self.revoke!(consent:, actor:, audit_action:, correlation_id:, revocation_reason:, audit_metadata: {})
      ActiveRecord::Base.transaction do
        previous_status = consent.status
        active_tokens_count = consent.access_tokens.where(revoked_at: nil).count
        transitioned = consent.revoke!

        if transitioned
          AuditTrail.record!(
            action: audit_action,
            actor: actor,
            target: consent,
            metadata: { from: previous_status, to: consent.status }.merge(audit_metadata)
          )
          enqueue_revoked_webhook!(
            consent:,
            correlation_id:,
            previous_status:,
            revocation_reason:,
            tokens_revoked: active_tokens_count
          )
        end

        transitioned
      end
    end

    def self.enqueue_authorized_webhook!(consent:, correlation_id:)
      event_id = WebhookDelivery.generate_event_id

      WebhookDelivery.enqueue!(
        developer_app: consent.developer_app,
        event_type: "consent.authorized",
        aggregate: consent,
        correlation_id: correlation_id,
        event_id: event_id,
        payload: Sandbox::PartnerEvent.consent_authorized(
          consent: consent,
          event_id: event_id,
          correlation_id: correlation_id
        )
      )
    end

    def self.enqueue_revoked_webhook!(consent:, correlation_id:, previous_status:, revocation_reason:, tokens_revoked:)
      event_id = WebhookDelivery.generate_event_id

      WebhookDelivery.enqueue!(
        developer_app: consent.developer_app,
        event_type: "consent.revoked",
        aggregate: consent,
        correlation_id: correlation_id,
        event_id: event_id,
        payload: Sandbox::PartnerEvent.consent_revoked(
          consent: consent,
          event_id: event_id,
          correlation_id: correlation_id,
          revocation_reason: revocation_reason,
          previous_status: previous_status,
          tokens_revoked: tokens_revoked
        )
      )
    end

    private_class_method :enqueue_authorized_webhook!, :enqueue_revoked_webhook!
  end
end
