require "test_helper"

class PlatformEndpointsTest < ActionDispatch::IntegrationTest
  test "readiness reports dependency status" do
    get "/ready"

    assert_response :success
    body = json_response
    assert_equal "ready", body.fetch("status")
    assert_equal "ok", body.fetch("dependencies").fetch("primary_database")
    assert_equal "ok", body.fetch("dependencies").fetch("cache_database")
    assert_equal "ok", body.fetch("dependencies").fetch("queue_database")
    assert_equal "ok", body.fetch("dependencies").fetch("cable_database")
  end

  test "platform probes bypass application rate limiting" do
    original_check = Security::RateLimiter.method(:check!)
    Security::RateLimiter.define_singleton_method(:check!) do |**|
      raise "rate limiter should not run for platform probes"
    end

    begin
      get "/up"
      assert_response :success

      get "/metrics"
      assert_response :success
    ensure
      Security::RateLimiter.define_singleton_method(:check!) { |**kwargs| original_check.call(**kwargs) }
    end
  end
end
