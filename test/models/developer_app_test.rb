require "test_helper"

class DeveloperAppTest < ActiveSupport::TestCase
  test "generates one-time client secret and stores only a digest" do
    app, secret = create_developer_app

    assert_match(/\Ask_sandbox_/, secret)
    assert app.authenticate_secret?(secret)
    refute_equal secret, app.client_secret_digest
    refute app.authenticate_secret?("wrong")
  end

  test "rejects unsupported active scenarios" do
    app = DeveloperApp.new(name: "Bad scenario", webhook_url: "https://example.test", active_scenario_code: "unknown")

    refute app.valid?
    assert_includes app.errors[:active_scenario_code], "is not supported"
  end
end
