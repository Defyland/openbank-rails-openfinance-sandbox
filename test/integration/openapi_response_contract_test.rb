require "test_helper"
require "yaml"

class OpenapiResponseContractTest < ActionDispatch::IntegrationTest
  test "openapi document defines versioned auth-protected endpoints" do
    document = YAML.load_file(Rails.root.join("openapi.yaml"))

    assert_equal "3.1.0", document.fetch("openapi")
    assert_includes document.fetch("paths").keys, "/v1/consents"
    assert_includes document.fetch("paths").keys, "/v1/oauth/token"
    assert_includes document.fetch("paths").keys, "/v1/payments"
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
end
