require "test_helper"

class PaymentInitiationTest < ActiveSupport::TestCase
  test "accepted payment debits account and writes ledger transaction" do
    customer, account = create_customer_with_account(balance_cents: 50_000)
    app, = create_developer_app
    consent = create_authorized_consent(app: app, customer: customer)
    token = issue_token(app: app, consent: consent)

    payment = Sandbox::PaymentInitiator.call!(
      developer_app: app,
      access_token: token,
      idempotency_key: "idem-1",
      correlation_id: "corr-1",
      params: {
        account_id: account.external_id,
        external_reference: "pix-1",
        amount_cents: 12_000,
        currency: "BRL",
        creditor_name: "Ana Lima",
        creditor_document: "99988877766",
        creditor_account: "0001/43210-1"
      }
    )

    assert_equal "accepted", payment.status
    assert_equal 38_000, account.reload.available_balance_cents
    assert_equal "payment", account.ledger_transactions.order(:created_at).last.category
  end

  test "idempotency key returns the original payment for the same payload" do
    customer, account = create_customer_with_account
    app, = create_developer_app
    consent = create_authorized_consent(app: app, customer: customer)
    token = issue_token(app: app, consent: consent)
    params = {
      account_id: account.external_id,
      external_reference: "pix-2",
      amount_cents: 2_000,
      currency: "BRL",
      creditor_name: "Ana Lima",
      creditor_document: "99988877766",
      creditor_account: "0001/43210-1"
    }

    first = Sandbox::PaymentInitiator.call!(developer_app: app, access_token: token, params: params, idempotency_key: "same", correlation_id: "corr")
    second = Sandbox::PaymentInitiator.call!(developer_app: app, access_token: token, params: params, idempotency_key: "same", correlation_id: "corr")

    assert_equal first.id, second.id
    assert_equal 1, PaymentInitiation.where(idempotency_key: "same").count
  end

  test "payment rejection scenario does not debit account" do
    customer, account = create_customer_with_account(balance_cents: 50_000)
    app, = create_developer_app
    app.update!(active_scenario_code: "payment_rejected")
    consent = create_authorized_consent(app: app, customer: customer)
    token = issue_token(app: app, consent: consent)

    payment = Sandbox::PaymentInitiator.call!(
      developer_app: app,
      access_token: token,
      idempotency_key: "idem-reject",
      correlation_id: "corr",
      params: {
        account_id: account.external_id,
        external_reference: "pix-reject",
        amount_cents: 10_000,
        currency: "BRL",
        creditor_name: "Ana Lima",
        creditor_document: "99988877766",
        creditor_account: "0001/43210-1"
      }
    )

    assert_equal "rejected", payment.status
    assert_equal "SANDBOX_PAYMENT_REJECTED", payment.failure_code
    assert_equal 50_000, account.reload.available_balance_cents
  end
end
