require "net/http"
require "openssl"
require "uri"

module Sandbox
  class WebhookHttpClient
    Response = Struct.new(:status, :body, keyword_init: false) do
      def success?
        status.to_i.between?(200, 299)
      end
    end

    class DeliveryError < StandardError; end

    def self.deliver!(delivery)
      uri = URI.parse(delivery.developer_app.webhook_url)
      raise DeliveryError, "webhook_url must be http or https" unless uri.is_a?(URI::HTTP)

      request = Net::HTTP::Post.new(uri)
      delivery.delivery_headers.each { |key, value| request[key] = value }
      request.body = delivery.canonical_payload

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = ENV.fetch("WEBHOOK_OPEN_TIMEOUT_SECONDS", 2).to_f
      http.read_timeout = ENV.fetch("WEBHOOK_READ_TIMEOUT_SECONDS", 5).to_f

      response = http.request(request)
      Response.new(response.code.to_i, response.body.to_s)
    rescue URI::InvalidURIError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError,
           Net::OpenTimeout, Net::ReadTimeout => error
      raise DeliveryError, "#{error.class}: #{error.message}"
    end
  end
end
