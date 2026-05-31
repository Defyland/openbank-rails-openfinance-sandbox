require "test_helper"

module Sandbox
  class WebhookEndpointPolicyTest < ActiveSupport::TestCase
    test "blocks localhost hostnames by default" do
      error = assert_raises(WebhookEndpointPolicy::UnsafeEndpointError) do
        WebhookEndpointPolicy.resolve!(URI.parse("http://localhost:3000/webhooks"))
      end

      assert_match "host is not allowed", error.message
    end

    test "blocks loopback addresses by default" do
      error = assert_raises(WebhookEndpointPolicy::UnsafeEndpointError) do
        WebhookEndpointPolicy.resolve!(URI.parse("http://127.0.0.1:3000/webhooks"))
      end

      assert_match "blocked network", error.message
    end

    test "blocks cloud metadata link-local addresses by default" do
      error = assert_raises(WebhookEndpointPolicy::UnsafeEndpointError) do
        WebhookEndpointPolicy.resolve!(URI.parse("http://169.254.169.254/latest/meta-data"))
      end

      assert_match "blocked network", error.message
    end

    test "allows private addresses only when explicitly enabled" do
      with_private_webhook_addresses_allowed do
        assert_equal "127.0.0.1", WebhookEndpointPolicy.resolve!(URI.parse("http://127.0.0.1:3000/webhooks"))
      end
    end

    private

    def with_private_webhook_addresses_allowed
      previous = ENV["WEBHOOK_ALLOW_PRIVATE_ADDRESSES"]
      ENV["WEBHOOK_ALLOW_PRIVATE_ADDRESSES"] = "true"
      yield
    ensure
      ENV["WEBHOOK_ALLOW_PRIVATE_ADDRESSES"] = previous
    end
  end
end
