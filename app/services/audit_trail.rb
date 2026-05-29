class AuditTrail
  def self.record!(action:, actor: nil, target: nil, metadata: {})
    actor ||= Current.user || Current.developer_app

    event = AuditEvent.create!(
      action: action,
      actor: actor,
      actor_identifier: identifier_for(actor),
      target: target,
      target_identifier: identifier_for(target),
      request_id: Current.request_id,
      correlation_id: Current.correlation_id,
      ip_address: Current.ip_address,
      user_agent: Current.user_agent,
      metadata: metadata.to_h.deep_stringify_keys
    )

    Rails.logger.info(JSON.generate(
      event: "audit",
      action: event.action,
      actor_type: event.actor_type,
      actor_identifier: event.actor_identifier,
      target_type: event.target_type,
      target_identifier: event.target_identifier,
      request_id: event.request_id,
      correlation_id: event.correlation_id,
      ip_address: event.ip_address,
      metadata: event.metadata
    ))

    event
  end

  def self.identifier_for(record)
    case record
    when nil
      nil
    when User
      record.email_address
    when DeveloperApp
      record.client_id
    when Consent, Account, PaymentInitiation
      record.external_id
    when WebhookDelivery
      record.event_id
    when SandboxCustomer
      record.external_id
    else
      record.respond_to?(:id) ? record.id.to_s : record.to_s
    end
  end

  private_class_method :identifier_for
end
