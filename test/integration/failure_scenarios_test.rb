require "test_helper"

class FailureScenariosTest < ActionDispatch::IntegrationTest
  test "expired consent scenario blocks token issuance" do
    customer, = create_customer_with_account
    app, secret = create_developer_app
    app.update!(active_scenario_code: "expired_consent")
    consent = create_authorized_consent(app: app, customer: customer)

    post "/v1/oauth/token", params: {
      token: {
        grant_type: "client_credentials",
        consent_id: consent.external_id
      }
    }, headers: client_headers(app, secret), as: :json

    assert_response :forbidden
    assert_equal "expired", consent.reload.status
  end

  test "same idempotency key with different payload is rejected" do
    customer, account = create_customer_with_account
    app, = create_developer_app
    consent = create_authorized_consent(app: app, customer: customer)
    token = issue_token(app: app, consent: consent)
    headers = bearer_headers(token).merge("Idempotency-Key" => "idem-conflict")

    payload = {
      payment: {
        account_id: account.external_id,
        external_reference: "pix-1",
        amount_cents: 1_000,
        currency: "BRL",
        creditor_name: "Ana Lima",
        creditor_document: "99988877766",
        creditor_account: "0001/43210-1"
      }
    }
    post "/v1/payments", params: payload, headers: headers, as: :json
    assert_response :created

    payload[:payment][:amount_cents] = 2_000
    post "/v1/payments", params: payload, headers: headers, as: :json

    assert_response :conflict
    assert_equal "conflict", json_response.dig("error", "code")
  end

  test "rate limiter returns retry metadata" do
    app, secret = create_developer_app(rate_limit_per_minute: 1)
    headers = client_headers(app, secret)

    get "/v1/developer_app", headers: headers
    assert_response :success

    get "/v1/developer_app", headers: headers
    assert_response :too_many_requests
    assert_equal "rate_limited", json_response.dig("error", "code")
    assert_equal "60", response.headers["Retry-After"]
  end
end
