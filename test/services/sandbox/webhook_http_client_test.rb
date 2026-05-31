require "socket"
require "test_helper"

module Sandbox
  class WebhookHttpClientTest < ActiveSupport::TestCase
    test "posts canonical payload and delivery headers to the webhook endpoint" do
      server = TCPServer.new("127.0.0.1", 0)
      port = server.addr.fetch(1)
      captured_request = Queue.new

      server_thread = Thread.new do
        client = server.accept
        header_block = +""
        while (line = client.gets)
          header_block << line
          break if line == "\r\n"
        end
        content_length = header_block[/content-length:\s*(\d+)/i, 1].to_i
        body = client.read(content_length)
        captured_request << [ header_block, body ]
        client.write "HTTP/1.1 202 Accepted\r\nContent-Length: 8\r\nConnection: close\r\n\r\naccepted"
        client.close
      end

      with_private_webhook_addresses_allowed do
        app, = create_developer_app(webhook_url: "http://127.0.0.1:#{port}/webhooks")
        delivery = WebhookDelivery.create!(
          developer_app: app,
          event_type: "payment.settled",
          aggregate_type: "PaymentInitiation",
          aggregate_id: 123,
          correlation_id: "corr-http-client",
          payload: { status: "settled", payment_id: "pay_123" }
        )

        response = WebhookHttpClient.deliver!(delivery)

        assert response.success?
        assert_equal 202, response.status
        headers, body = captured_request.pop
        normalized_headers = headers.downcase
        assert_includes headers, "POST /webhooks HTTP/1.1"
        assert_includes normalized_headers, "content-type: application/json"
        assert_includes normalized_headers, "x-openbank-event-id: #{delivery.event_id}".downcase
        assert_includes normalized_headers, "x-openbank-event-type: payment.settled"
        assert_includes normalized_headers, "x-openbank-signature: #{delivery.signature}".downcase
        assert_includes normalized_headers, "x-openbank-signature-timestamp: #{delivery.signature_timestamp.iso8601}".downcase
        assert_includes normalized_headers, "x-correlation-id: corr-http-client"
        assert_equal delivery.canonical_payload, body
      end
    ensure
      server&.close
      server_thread&.kill unless server_thread&.join(1)
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
