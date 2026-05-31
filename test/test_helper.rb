ENV["RAILS_ENV"] ||= "test"

require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
end

require_relative "../config/environment"
require "rails/test_help"
require "active_job/test_helper"
Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |file| require file }

class TestWebhookHttpClient
  def self.deliver!(_delivery)
    Sandbox::WebhookHttpClient::Response.new(202, "accepted")
  end
end

Rails.application.config.x.webhook_http_client = TestWebhookHttpClient

module ActiveSupport
  class TestCase
    parallelize(workers: 1)
    fixtures :all

    setup do
      Rails.cache.clear
      clear_enqueued_jobs
      clear_performed_jobs
    end

    include ActiveJob::TestHelper
    include ApiTestHelper
    include OpenapiContractAssertions
  end
end
