Sandbox::ScenarioRegistry.all.each do |definition|
  SandboxScenario.find_or_create_by!(code: definition.fetch(:code)) do |scenario|
    scenario.name = definition.fetch(:name)
    scenario.description = definition.fetch(:description)
    scenario.config = definition.fetch(:config)
  end
end

seed_operator = !Rails.env.production? || ENV["SEED_OPERATOR"] == "true"
seed_demo_data = !Rails.env.production? || ENV["SEED_DEMO_DATA"] == "true"

if seed_operator
  operator_email =
    if Rails.env.production?
      ENV.fetch("OPERATOR_EMAIL")
    else
      ENV.fetch("OPERATOR_EMAIL", "ops@example.test")
    end
  operator_password =
    if Rails.env.production?
      ENV.fetch("OPERATOR_PASSWORD")
    else
      ENV.fetch("OPERATOR_PASSWORD", "password-12345")
    end

  raise "OPERATOR_PASSWORD must be at least 12 characters" if operator_password.length < 12

  operator = User.find_or_initialize_by(email_address: operator_email)
  operator.password = operator_password if operator.new_record? || ENV["OPERATOR_PASSWORD"].present?
  operator.save!
end

if seed_demo_data
  demo_client_secret =
    if Rails.env.production?
      ENV.fetch("DEMO_CLIENT_SECRET")
    else
      ENV.fetch("DEMO_CLIENT_SECRET", "sk_sandbox_demo_secret")
    end

  customer = SandboxCustomer.find_or_create_by!(document_number: "11122233344") do |record|
    record.external_id = "cus_demo_retail"
    record.full_name = "Marina Costa"
    record.segment = "retail"
    record.risk_profile = "standard"
  end

  checking = Account.find_or_create_by!(external_id: "acc_demo_checking") do |account|
    account.sandbox_customer = customer
    account.account_type = "checking"
    account.branch_code = "0001"
    account.number = "123456"
    account.check_digit = "7"
    account.currency = "BRL"
    account.available_balance_cents = 1_250_000
  end

  [
    [ "credit", 750_000, "Salary payment", "income", 5.days.ago ],
    [ "debit", 12_900, "Grocery store", "merchant", 3.days.ago ],
    [ "debit", 8_500, "Ride sharing", "transport", 1.day.ago ]
  ].each_with_index do |(type, amount, description, category, posted_at), index|
    LedgerTransaction.find_or_create_by!(account: checking, external_id: "txn_demo_#{index}") do |transaction|
      transaction.transaction_type = type
      transaction.amount_cents = amount
      transaction.currency = "BRL"
      transaction.description = description
      transaction.category = category
      transaction.posted_at = posted_at
    end
  end

  developer_app = DeveloperApp.find_or_initialize_by(client_id: "app_demo_partner")
  if developer_app.new_record?
    developer_app.name = "Demo Partner"
    developer_app.client_secret_digest = DeveloperApp.digest(demo_client_secret)
    developer_app.webhook_url = "https://partner.example.test/webhooks"
    developer_app.status = "active"
    developer_app.active_scenario_code = "happy_path"
    developer_app.rate_limit_per_minute = 120
  end
  developer_app.save!

  consent = Consent.find_or_create_by!(developer_app: developer_app, external_id: "cns_demo_authorized") do |record|
    record.sandbox_customer = customer
    record.status = "authorized"
    record.permissions = Consent::PERMISSIONS
    record.authorized_at = 1.hour.ago
    record.expires_at = 30.days.from_now
    record.correlation_id = "corr-demo-consent"
  end

  payment = PaymentInitiation.find_or_create_by!(developer_app: developer_app, idempotency_key: "idem-demo-payment-001") do |record|
    record.consent = consent
    record.account = checking
    record.external_id = "pay_demo_accepted"
    record.external_reference = "pix-demo-001"
    record.request_fingerprint = DeveloperApp.digest("pix-demo-001:9900:BRL")
    record.status = "settled"
    record.amount_cents = 9_900
    record.currency = "BRL"
    record.creditor_name = "Paula Santos"
    record.creditor_document = "12345678901"
    record.creditor_account = "0001/12345-6"
    record.correlation_id = "corr-demo-payment"
    record.processed_at = 20.minutes.ago
  end

  WebhookDelivery.find_or_create_by!(event_id: "evt_demo_payment_settled") do |delivery|
    delivery.developer_app = developer_app
    delivery.event_type = "payment.settled"
    delivery.aggregate_type = PaymentInitiation.name
    delivery.aggregate_id = payment.id
    delivery.status = "failed"
    delivery.payload = {
      event_type: "payment.settled",
      schema_version: 1,
      payment_id: payment.external_id,
      status: payment.status,
      amount_cents: payment.amount_cents
    }
    delivery.correlation_id = "corr-demo-payment"
    delivery.attempts_count = 1
    delivery.next_attempt_at = 5.minutes.from_now
    delivery.last_error = "Sandbox demo delivery failed; replay it from /ops/webhook_deliveries."
  end
end
