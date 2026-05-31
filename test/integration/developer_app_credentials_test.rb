require "test_helper"

class DeveloperAppCredentialsTest < ActionDispatch::IntegrationTest
  test "client secret rotation returns a one-time replacement and invalidates the old secret" do
    app, old_secret = create_developer_app

    post "/v1/developer_app/client_secret/rotate", headers: client_headers(app, old_secret), as: :json

    assert_response :success
    assert_openapi_response "/v1/developer_app/client_secret/rotate", :post, 200, json_response
    new_secret = json_response.fetch("developer_app").fetch("client_secret")
    refute_equal old_secret, new_secret
    assert new_secret.start_with?("sk_sandbox_")
    assert_equal 1, AuditEvent.where(action: "v1.developer_app.client_secret_rotated", target: app).count

    get "/v1/developer_app", headers: client_headers(app, old_secret)
    assert_response :unauthorized

    get "/v1/developer_app", headers: client_headers(app, new_secret)
    assert_response :success
  end

  test "webhook signing secret rotation affects new deliveries only" do
    app, client_secret, old_signing_secret = create_developer_app
    existing_delivery = WebhookDelivery.create!(
      developer_app: app,
      event_type: "payment.settled",
      aggregate_type: "PaymentInitiation",
      aggregate_id: 321,
      payload: { "status" => "settled" }
    )
    old_signature = existing_delivery.signature

    post "/v1/developer_app/webhook_signing_secret/rotate", headers: client_headers(app, client_secret), as: :json

    assert_response :success
    assert_openapi_response "/v1/developer_app/webhook_signing_secret/rotate", :post, 200, json_response
    new_signing_secret = json_response.fetch("developer_app").fetch("webhook_signing_secret")
    refute_equal old_signing_secret, new_signing_secret
    assert new_signing_secret.start_with?("whsec_sandbox_")
    assert_equal 1, AuditEvent.where(action: "v1.developer_app.webhook_signing_secret_rotated", target: app).count

    existing_delivery.update!(status: "failed", last_error: "force operational update")
    assert_equal old_signature, existing_delivery.reload.signature

    new_delivery = WebhookDelivery.create!(
      developer_app: app.reload,
      event_type: "payment.settled",
      aggregate_type: "PaymentInitiation",
      aggregate_id: 322,
      payload: { "status" => "settled" }
    )
    expected_signature = OpenSSL::HMAC.hexdigest(
      "SHA256",
      new_signing_secret,
      "#{new_delivery.signature_timestamp.iso8601}.#{new_delivery.canonical_payload}"
    )
    assert_equal expected_signature, new_delivery.signature
  end
end
