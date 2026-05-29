require "test_helper"
require "stringio"

class JsonLogFormatterTest < ActiveSupport::TestCase
  test "serializes structured payloads with request context" do
    Current.request_id = "req-log-test"
    Current.correlation_id = "corr-log-test"

    output = StringIO.new
    logger = ActiveSupport::Logger.new(output)
    logger.formatter = JsonLogFormatter.new
    logger = ActiveSupport::TaggedLogging.new(logger)

    logger.tagged("api") do
      logger.info(JSON.generate(event: "audit", action: "ops.session.created"))
    end

    payload = JSON.parse(output.string)
    assert_equal "INFO", payload.fetch("severity")
    assert_equal "audit", payload.fetch("event")
    assert_equal "ops.session.created", payload.fetch("action")
    assert_equal "req-log-test", payload.fetch("request_id")
    assert_equal "corr-log-test", payload.fetch("correlation_id")
    assert_equal [ "api" ], payload.fetch("tags")
  ensure
    Current.reset
  end
end
