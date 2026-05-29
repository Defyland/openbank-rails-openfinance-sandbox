require "test_helper"

class OpenfinancePartnerFlowTest < ActionDispatch::IntegrationTest
  test "partner creates app, authorizes consent, reads accounts, initiates payment and receives webhook" do
    customer, account = create_customer_with_account(balance_cents: 100_000)

    post "/v1/developer_apps", params: {
      developer_app: {
        name: "Acme Fintech QA",
        webhook_url: "https://partner.example.test/webhooks",
        rate_limit_per_minute: 120
      }
    }, as: :json

    assert_response :created
    app_payload = json_response.fetch("developer_app")
    app = DeveloperApp.find_by!(client_id: app_payload.fetch("id"))
    secret = app_payload.fetch("client_secret")
    assert_equal 1, AuditEvent.where(action: "v1.developer_app.created", target: app).count
    headers = client_headers(app, secret)

    post "/v1/consents", params: {
      consent: {
        customer_document_number: customer.document_number,
        permissions: DEFAULT_PERMISSIONS
      }
    }, headers: headers, as: :json

    assert_response :created
    consent_id = json_response.fetch("consent").fetch("id")
    consent = app.consents.find_by!(external_id: consent_id)
    assert_equal 1, AuditEvent.where(action: "v1.consent.created", target: consent).count

    perform_enqueued_jobs do
      patch "/v1/consents/#{consent_id}/authorize", headers: headers, as: :json
    end
    assert_response :success
    assert_equal "authorized", json_response.fetch("consent").fetch("status")
    assert_equal 1, AuditEvent.where(action: "v1.consent.authorized", target: consent).count

    post "/v1/oauth/token", params: {
      token: {
        grant_type: "client_credentials",
        consent_id: consent_id
      }
    }, headers: headers, as: :json

    assert_response :created
    access_token = json_response.fetch("token").fetch("access_token")
    bearer = { "Authorization" => "Bearer #{access_token}", "X-Correlation-ID" => "corr-flow" }

    get "/v1/accounts", headers: bearer
    assert_response :success
    assert_equal [ account.external_id ], json_response.fetch("accounts").map { |item| item.fetch("id") }

    get "/v1/accounts/#{account.external_id}/balances", headers: bearer
    assert_response :success
    assert_equal 100_000, json_response.fetch("balance").fetch("available_balance_cents")

    get "/v1/accounts/#{account.external_id}/transactions", headers: bearer
    assert_response :success
    assert_equal 1, json_response.fetch("transactions").size

    perform_enqueued_jobs do
      post "/v1/payments", params: {
        payment: {
          account_id: account.external_id,
          external_reference: "pix-flow-1",
          amount_cents: 25_000,
          currency: "BRL",
          creditor_name: "Ana Lima",
          creditor_document: "99988877766",
          creditor_account: "0001/43210-1"
        }
      }, headers: bearer.merge("Idempotency-Key" => "payment-flow-1"), as: :json
    end

    assert_response :created
    payment = json_response.fetch("payment")
    assert_equal "accepted", payment.fetch("status")
    assert_equal 75_000, account.reload.available_balance_cents
    assert_equal 1, AuditEvent.where(action: "v1.payment.created").count

    get "/v1/webhook_deliveries", headers: headers
    assert_response :success
    delivery = json_response.fetch("webhook_deliveries").find { |item| item.fetch("event_type") == "payment.accepted" }
    assert_equal "delivered", delivery.fetch("status")
    assert_equal "corr-flow", delivery.fetch("correlation_id")
  end

  test "repeated consent lifecycle calls stay idempotent and do not duplicate webhooks" do
    customer, = create_customer_with_account
    app, secret = create_developer_app
    headers = client_headers(app, secret)

    post "/v1/consents", params: {
      consent: {
        customer_document_number: customer.document_number,
        permissions: DEFAULT_PERMISSIONS
      }
    }, headers: headers, as: :json

    assert_response :created
    consent_id = json_response.fetch("consent").fetch("id")

    perform_enqueued_jobs do
      patch "/v1/consents/#{consent_id}/authorize", headers: headers, as: :json
    end
    assert_response :success
    assert_equal 1, WebhookDelivery.where(event_type: "consent.authorized").count
    assert_equal 1, AuditEvent.where(action: "v1.consent.authorized").count

    perform_enqueued_jobs do
      patch "/v1/consents/#{consent_id}/authorize", headers: headers, as: :json
    end
    assert_response :success
    assert_equal 1, WebhookDelivery.where(event_type: "consent.authorized").count

    perform_enqueued_jobs do
      patch "/v1/consents/#{consent_id}/revoke", headers: headers, as: :json
    end
    assert_response :success
    assert_equal 1, WebhookDelivery.where(event_type: "consent.revoked").count
    assert_equal 1, AuditEvent.where(action: "v1.consent.revoked").count

    perform_enqueued_jobs do
      patch "/v1/consents/#{consent_id}/revoke", headers: headers, as: :json
    end
    assert_response :success
    assert_equal 1, WebhookDelivery.where(event_type: "consent.revoked").count
    assert_equal 1, AuditEvent.where(action: "v1.consent.revoked").count
  end
end
