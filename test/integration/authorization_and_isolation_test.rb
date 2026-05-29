require "test_helper"

class AuthorizationAndIsolationTest < ActionDispatch::IntegrationTest
  test "account access requires the correct permission" do
    customer, = create_customer_with_account
    app, = create_developer_app
    consent = create_authorized_consent(app: app, customer: customer, permissions: %w[BALANCES_READ])
    token = issue_token(app: app, consent: consent)

    get "/v1/accounts", headers: bearer_headers(token)

    assert_response :forbidden
    assert_equal "forbidden", json_response.dig("error", "code")
  end

  test "token cannot read another customer account" do
    customer, = create_customer_with_account(document_number: "22233344455")
    other_customer, other_account = create_customer_with_account(document_number: "55566677788")
    app, = create_developer_app
    create_authorized_consent(app: app, customer: other_customer)
    consent = create_authorized_consent(app: app, customer: customer)
    token = issue_token(app: app, consent: consent)

    get "/v1/accounts/#{other_account.external_id}", headers: bearer_headers(token)

    assert_response :forbidden
    assert_equal "Account is outside the authorized customer consent.", json_response.dig("error", "message")
  end

  test "client credentials cannot manage another app consent" do
    customer, = create_customer_with_account
    app, = create_developer_app
    other_app, other_secret = create_developer_app
    consent = create_authorized_consent(app: app, customer: customer)

    get "/v1/consents/#{consent.external_id}", headers: client_headers(other_app, other_secret)

    assert_response :not_found
  end

  test "revoked consent makes token unusable" do
    customer, = create_customer_with_account
    app, = create_developer_app
    consent = create_authorized_consent(app: app, customer: customer)
    token = issue_token(app: app, consent: consent)
    consent.revoke!

    get "/v1/accounts", headers: bearer_headers(token)

    assert_response :unauthorized
    assert_equal "Bearer token expired or revoked.", json_response.dig("error", "message")
  end
end
