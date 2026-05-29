ENV["RAILS_ENV"] ||= "test"
ENV["DATABASE_ADAPTER"] ||= "sqlite3"

require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
end

require_relative "../config/environment"
require "rails/test_help"
require "active_job/test_helper"
Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |file| require file }

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
  end
end
