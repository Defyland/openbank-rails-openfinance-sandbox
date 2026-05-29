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
end
