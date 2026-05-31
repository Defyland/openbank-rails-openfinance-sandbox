require "test_helper"
require "yaml"

class OpenapiResponseContractTest < ActionDispatch::IntegrationTest
  test "openapi document defines versioned auth-protected endpoints" do
    document = YAML.load_file(Rails.root.join("openapi.yaml"))

    assert_equal "3.1.0", document.fetch("openapi")
    assert_openapi_document_valid
    assert_includes document.fetch("paths").keys, "/v1/consents"
    assert_includes document.fetch("paths").keys, "/v1/oauth/token"
    assert_includes document.fetch("paths").keys, "/v1/payments"
    assert_includes document.fetch("paths").keys, "/v1/developer_app/client_secret/rotate"
    assert_includes document.fetch("paths").keys, "/v1/developer_app/webhook_signing_secret/rotate"
    assert document.dig("components", "securitySchemes", "ClientCredentials")
    assert document.dig("components", "securitySchemes", "BearerAuth")
  end

  test "validation errors use standard error envelope" do
    post "/v1/developer_apps", params: { developer_app: { name: "" } }, as: :json

    assert_response :unprocessable_entity
    error = json_response.fetch("error")
    assert_equal "validation_failed", error.fetch("code")
    assert error.fetch("request_id")
    assert error.fetch("correlation_id")
  end

  test "documented partner flow responses match OpenAPI schemas" do
    customer, account = create_customer_with_account(balance_cents: 100_000)

    post "/v1/developer_apps", params: {
      developer_app: {
        name: "Contract QA",
        webhook_url: "https://partner.example.test/webhooks",
        rate_limit_per_minute: 120
      }
    }, as: :json
    assert_response :created
    assert_openapi_response "/v1/developer_apps", :post, 201, json_response

    app_payload = json_response.fetch("developer_app")
    app = DeveloperApp.find_by!(client_id: app_payload.fetch("id"))
    headers = client_headers(app, app_payload.fetch("client_secret"))

    post "/v1/consents", params: {
      consent: {
        customer_document_number: customer.document_number,
        permissions: DEFAULT_PERMISSIONS
      }
    }, headers: headers, as: :json
    assert_response :created
    assert_openapi_response "/v1/consents", :post, 201, json_response
    consent_id = json_response.fetch("consent").fetch("id")

    patch "/v1/consents/#{consent_id}/authorize", headers: headers, as: :json
    assert_response :success
    assert_openapi_response "/v1/consents/{consent_id}/authorize", :patch, 200, json_response

    post "/v1/oauth/token", params: {
      token: {
        grant_type: "client_credentials",
        consent_id: consent_id
      }
    }, headers: headers, as: :json
    assert_response :created
    assert_openapi_response "/v1/oauth/token", :post, 201, json_response
    bearer = {
      "Authorization" => "Bearer #{json_response.fetch('token').fetch('access_token')}",
      "X-Correlation-ID" => "corr-contract"
    }

    get "/v1/accounts", headers: bearer
    assert_response :success
    assert_openapi_response "/v1/accounts", :get, 200, json_response

    get "/v1/accounts/#{account.external_id}/balances", headers: bearer
    assert_response :success
    assert_openapi_response "/v1/accounts/{account_id}/balances", :get, 200, json_response

    post "/v1/payments", params: {
      payment: {
        account_id: account.external_id,
        external_reference: "pix-contract",
        amount_cents: 10_000,
        currency: "BRL",
        creditor_name: "Ana Lima",
        creditor_document: "99988877766",
        creditor_account: "0001/43210-1"
      }
    }, headers: bearer.merge("Idempotency-Key" => "contract-payment"), as: :json
    assert_response :created
    assert_openapi_response "/v1/payments", :post, 201, json_response

    get "/v1/webhook_deliveries", headers: headers
    assert_response :success
    assert_openapi_response "/v1/webhook_deliveries", :get, 200, json_response
  end
end
