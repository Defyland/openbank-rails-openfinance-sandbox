require "test_helper"

class PaymentInitiationTest < ActiveSupport::TestCase
  test "settled payment debits account and writes lifecycle webhooks" do
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

    assert_equal "settled", payment.status
    assert_equal 38_000, account.reload.available_balance_cents
    assert_equal "payment", account.ledger_transactions.order(:created_at).last.category
    assert_equal 1, WebhookDelivery.where(event_type: "payment.created", aggregate_id: payment.id).count
    assert_equal 1, WebhookDelivery.where(event_type: "payment.settled", aggregate_id: payment.id).count
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

  test "idempotency recovers when a concurrent insert wins the race" do
    customer, account = create_customer_with_account
    app, = create_developer_app
    consent = create_authorized_consent(app: app, customer: customer)
    token = issue_token(app: app, consent: consent)
    params = {
      account_id: account.external_id,
      external_reference: "pix-race",
      amount_cents: 2_000,
      currency: "BRL",
      creditor_name: "Ana Lima",
      creditor_document: "99988877766",
      creditor_account: "0001/43210-1"
    }

    existing = Sandbox::PaymentInitiator.call!(
      developer_app: app,
      access_token: token,
      params: params,
      idempotency_key: "race",
      correlation_id: "corr"
    )
    first_lookup = true
    find_by_stub = lambda do |*args, **kwargs|
      if args.empty? && kwargs[:idempotency_key] == "race" && first_lookup
        first_lookup = false
        nil
      else
        scope = args.empty? ? PaymentInitiation.all : PaymentInitiation.where(*args)
        scope.find_by(**kwargs)
      end
    end
    create_stub = ->(**) { raise ActiveRecord::RecordNotUnique, "duplicate idempotency key" }

    original_find_by = PaymentInitiation.method(:find_by)
    original_create = PaymentInitiation.method(:create!)
    begin
      PaymentInitiation.define_singleton_method(:find_by, find_by_stub)
      PaymentInitiation.define_singleton_method(:create!, create_stub)

      duplicate = Sandbox::PaymentInitiator.call!(
        developer_app: app,
        access_token: token,
        params: params,
        idempotency_key: "race",
        correlation_id: "corr"
      )
    ensure
      PaymentInitiation.define_singleton_method(:find_by) { |*args, **kwargs| original_find_by.call(*args, **kwargs) }
      PaymentInitiation.define_singleton_method(:create!) { |*args, **kwargs| original_create.call(*args, **kwargs) }
    end

    assert_equal existing.id, duplicate.id
    refute duplicate.created_by_request?
    assert_equal 1, PaymentInitiation.where(idempotency_key: "race").count
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
    assert_equal "SCENARIO_REJECTED", payment.failure_code
    assert_equal 50_000, account.reload.available_balance_cents
    assert_equal 1, WebhookDelivery.where(event_type: "payment.created", aggregate_id: payment.id).count
    assert_equal 1, WebhookDelivery.where(event_type: "payment.rejected", aggregate_id: payment.id).count
  end
end
