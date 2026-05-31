module ApiTestHelper
  DEFAULT_PERMISSIONS = %w[ACCOUNTS_READ BALANCES_READ TRANSACTIONS_READ PAYMENTS_INITIATE WEBHOOKS_READ].freeze

  def create_customer_with_account(balance_cents: 1_000_000, document_number: nil)
    document_number ||= SecureRandom.random_number(10**11).to_s.rjust(11, "0")

    customer = SandboxCustomer.create!(
      external_id: "cus_#{SecureRandom.hex(4)}",
      document_number: document_number,
      full_name: "Marina Costa",
      segment: "retail",
      risk_profile: "standard"
    )
    account = Account.create!(
      sandbox_customer: customer,
      external_id: "acc_#{SecureRandom.hex(4)}",
      account_type: "checking",
      branch_code: SecureRandom.random_number(9999).to_s.rjust(4, "0"),
      number: SecureRandom.random_number(999_999).to_s.rjust(6, "0"),
      check_digit: SecureRandom.random_number(9).to_s,
      available_balance_cents: balance_cents
    )
    LedgerTransaction.create!(
      account: account,
      transaction_type: "credit",
      amount_cents: balance_cents,
      description: "Initial sandbox balance",
      category: "seed",
      posted_at: 2.days.ago
    )
    [ customer, account ]
  end

  def create_developer_app(rate_limit_per_minute: 120, webhook_url: "https://partner.example.test/webhooks")
    app = DeveloperApp.create!(
      name: "Partner QA",
      webhook_url: webhook_url,
      rate_limit_per_minute: rate_limit_per_minute
    )
    [ app, app.plain_client_secret, app.plain_webhook_signing_secret || app.webhook_signing_secret ]
  end

  def client_headers(app, secret)
    {
      "X-Client-Id" => app.client_id,
      "X-Client-Secret" => secret,
      "X-Correlation-ID" => "corr-test-#{SecureRandom.hex(4)}"
    }
  end

  def bearer_headers(token)
    {
      "Authorization" => "Bearer #{token.plain_token}",
      "X-Correlation-ID" => "corr-test-#{SecureRandom.hex(4)}"
    }
  end

  def create_authorized_consent(app:, customer:, permissions: DEFAULT_PERMISSIONS)
    Consent.create!(
      developer_app: app,
      sandbox_customer: customer,
      permissions: permissions,
      status: "authorized",
      authorized_at: Time.current,
      expires_at: 30.days.from_now
    )
  end

  def issue_token(app:, consent:)
    AccessToken.issue!(developer_app: app, consent: consent)
  end

  def json_response
    JSON.parse(response.body)
  end
end
