module ApiSerializer
  module_function

  def developer_app(app, include_secret: false)
    payload = {
      id: app.client_id,
      name: app.name,
      webhook_url: app.webhook_url,
      status: app.status,
      active_scenario_code: app.active_scenario_code,
      rate_limit_per_minute: app.rate_limit_per_minute,
      created_at: app.created_at&.iso8601
    }
    payload[:client_secret] = app.plain_client_secret if include_secret
    payload
  end

  def consent(consent)
    {
      id: consent.external_id,
      status: consent.status,
      customer_id: consent.sandbox_customer.external_id,
      permissions: consent.permissions,
      expires_at: consent.expires_at.iso8601,
      authorized_at: consent.authorized_at&.iso8601,
      revoked_at: consent.revoked_at&.iso8601,
      correlation_id: consent.correlation_id
    }.compact
  end

  def token(access_token)
    {
      access_token: access_token.plain_token,
      token_type: "Bearer",
      expires_in: (access_token.expires_at - Time.current).to_i,
      expires_at: access_token.expires_at.iso8601,
      consent_id: access_token.consent.external_id,
      permissions: access_token.permissions
    }
  end

  def account(account)
    {
      id: account.external_id,
      type: account.account_type,
      branch_code: account.branch_code,
      number: account.number,
      check_digit: account.check_digit,
      currency: account.currency,
      status: account.status
    }
  end

  def balance(account)
    {
      account_id: account.external_id,
      currency: account.currency,
      available_balance_cents: account.available_balance_cents,
      updated_at: account.updated_at.iso8601
    }
  end

  def transaction(transaction)
    {
      id: transaction.external_id,
      account_id: transaction.account.external_id,
      type: transaction.transaction_type,
      amount_cents: transaction.amount_cents,
      signed_amount_cents: transaction.signed_amount_cents,
      currency: transaction.currency,
      description: transaction.description,
      category: transaction.category,
      posted_at: transaction.posted_at.iso8601
    }
  end

  def payment(payment)
    {
      id: payment.external_id,
      external_reference: payment.external_reference,
      account_id: payment.account.external_id,
      status: payment.status,
      amount_cents: payment.amount_cents,
      currency: payment.currency,
      creditor_name: payment.creditor_name,
      creditor_document: payment.creditor_document,
      creditor_account: payment.creditor_account,
      failure_code: payment.failure_code,
      correlation_id: payment.correlation_id,
      processed_at: payment.processed_at&.iso8601
    }.compact
  end

  def webhook_delivery(delivery)
    {
      id: delivery.event_id,
      event_type: delivery.event_type,
      aggregate_type: delivery.aggregate_type,
      aggregate_id: delivery.aggregate_id,
      status: delivery.status,
      attempts_count: delivery.attempts_count,
      next_attempt_at: delivery.next_attempt_at&.iso8601,
      delivered_at: delivery.delivered_at&.iso8601,
      signature: delivery.signature,
      correlation_id: delivery.correlation_id,
      last_error: delivery.last_error,
      payload: delivery.payload
    }.compact
  end

  def scenario(definition)
    {
      code: definition.fetch(:code),
      name: definition.fetch(:name),
      description: definition.fetch(:description),
      config: definition.fetch(:config)
    }
  end
end
