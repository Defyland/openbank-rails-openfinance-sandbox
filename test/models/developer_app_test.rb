require "test_helper"

class DeveloperAppTest < ActiveSupport::TestCase
  test "generates one-time client secret and stores only a digest" do
    app, secret = create_developer_app

    assert_match(/\Ask_sandbox_/, secret)
    assert app.authenticate_secret?(secret)
    refute_equal secret, app.client_secret_digest
    refute app.authenticate_secret?("wrong")
  end

  test "generates a partner-verifiable webhook signing secret" do
    app, = create_developer_app
    signing_secret = app.plain_webhook_signing_secret

    assert_match(/\Awhsec_sandbox_/, signing_secret)
    assert_equal signing_secret, app.webhook_signing_secret
    refute_includes app.webhook_signing_secret_ciphertext, signing_secret
  end

  test "requires a valid http webhook url" do
    app = DeveloperApp.new(name: "Bad webhook", webhook_url: "javascript:alert(1)")

    refute app.valid?
    assert_includes app.errors[:webhook_url], "must be an http or https URL"
  end

  test "rejects unsupported active scenarios" do
    app = DeveloperApp.new(name: "Bad scenario", webhook_url: "https://example.test", active_scenario_code: "unknown")

    refute app.valid?
    assert_includes app.errors[:active_scenario_code], "is not supported"
  end
end
