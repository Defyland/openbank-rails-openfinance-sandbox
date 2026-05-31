require "test_helper"
require "json_schemer"

module Sandbox
  class PartnerEventContractTest < ActiveSupport::TestCase
    test "consent authorized event matches the published v1 schema" do
      customer, = create_customer_with_account
      app, = create_developer_app
      consent = create_authorized_consent(app: app, customer: customer)

      event = PartnerEvent.consent_authorized(
        consent: consent,
        event_id: WebhookDelivery.generate_event_id,
        correlation_id: "corr-contract"
      )

      assert_event_matches_schema event, "consent.authorized.v1"
    end

    test "consent revoked event matches the published v1 schema" do
      customer, = create_customer_with_account
      app, = create_developer_app
      consent = create_authorized_consent(app: app, customer: customer)
      consent.revoke!

      event = PartnerEvent.consent_revoked(
        consent: consent,
        event_id: WebhookDelivery.generate_event_id,
        correlation_id: "corr-contract",
        revocation_reason: "partner_request",
        previous_status: "authorized",
        tokens_revoked: 0
      )

      assert_event_matches_schema event, "consent.revoked.v1"
    end

    test "payment lifecycle events match the published v1 schemas" do
      customer, account = create_customer_with_account(balance_cents: 100_000)
      app, = create_developer_app
      consent = create_authorized_consent(app: app, customer: customer)
      token = issue_token(app: app, consent: consent)

      payment = Sandbox::PaymentInitiator.call!(
        developer_app: app,
        access_token: token,
        idempotency_key: "idem-contract-settled",
        correlation_id: "corr-contract",
        params: payment_params(account)
      )
      ledger_transaction = account.ledger_transactions.order(:created_at).last

      assert_event_matches_schema PartnerEvent.payment_created(
        payment: payment,
        event_id: WebhookDelivery.generate_event_id,
        correlation_id: "corr-contract"
      ), "payment.created.v1"
      assert_event_matches_schema PartnerEvent.payment_settled(
        payment: payment,
        ledger_transaction: ledger_transaction,
        event_id: WebhookDelivery.generate_event_id,
        correlation_id: "corr-contract"
      ), "payment.settled.v1"

      rejected_app, = create_developer_app
      rejected_app.update!(active_scenario_code: "payment_rejected")
      rejected_consent = create_authorized_consent(app: rejected_app, customer: customer)
      rejected_token = issue_token(app: rejected_app, consent: rejected_consent)
      rejected_payment = Sandbox::PaymentInitiator.call!(
        developer_app: rejected_app,
        access_token: rejected_token,
        idempotency_key: "idem-contract-rejected",
        correlation_id: "corr-contract",
        params: payment_params(account, external_reference: "pix-rejected")
      )

      assert_event_matches_schema PartnerEvent.payment_rejected(
        payment: rejected_payment,
        event_id: WebhookDelivery.generate_event_id,
        correlation_id: "corr-contract"
      ), "payment.rejected.v1"
    end

    private

    def assert_event_matches_schema(event, schema_name)
      errors = event_schema(schema_name).validate(JSON.parse(JSON.generate(event))).to_a
      assert_empty format_schema_errors(errors), "#{schema_name} contract drifted"
    end

    def event_schema(schema_name)
      @event_schemas ||= {}
      @event_schemas[schema_name] ||= JSONSchemer.schema(
        JSON.parse(Rails.root.join("docs/events/#{schema_name}.json").read)
      )
    end

    def payment_params(account, external_reference: "pix-contract")
      {
        account_id: account.external_id,
        external_reference: external_reference,
        amount_cents: 10_000,
        currency: "BRL",
        creditor_name: "Ana Lima",
        creditor_document: "99988877766",
        creditor_account: "0001/43210-1"
      }
    end

    def format_schema_errors(errors)
      errors.map do |error|
        "#{error.fetch('data_pointer', '/')}: #{error.fetch('type')} #{error['details'].inspect}".strip
      end
    end
  end
end
