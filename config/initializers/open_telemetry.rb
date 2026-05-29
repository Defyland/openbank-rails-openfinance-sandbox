if defined?(OpenTelemetry::SDK) && (ENV["OTEL_ENABLED"] == "true" || ENV["OTEL_EXPORTER_OTLP_ENDPOINT"].present?)
  OpenTelemetry::SDK.configure do |config|
    config.service_name = ENV.fetch("OTEL_SERVICE_NAME", "openbank-sandbox")
    config.use "OpenTelemetry::Instrumentation::Rack"
    config.use "OpenTelemetry::Instrumentation::ActionPack"
    config.use "OpenTelemetry::Instrumentation::ActiveRecord"
    config.use "OpenTelemetry::Instrumentation::ActiveJob"
    config.use "OpenTelemetry::Instrumentation::ActiveSupport"
  end
end
