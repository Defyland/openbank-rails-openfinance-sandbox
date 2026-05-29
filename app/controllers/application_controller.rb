class ApplicationController < ActionController::Base
  include Authentication

  before_action :assign_request_context
  after_action :set_observability_headers

  allow_browser versions: :modern
  stale_when_importmap_changes

  private

  def assign_request_context
    Current.request_id = request.request_id
    Current.correlation_id = request.headers["X-Correlation-ID"].presence || request.request_id
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
  end

  def set_observability_headers
    response.set_header("X-Request-ID", Current.request_id || request.request_id)
    response.set_header("X-Correlation-ID", Current.correlation_id) if Current.correlation_id.present?

    span = OpenTelemetry::Trace.current_span
    return if span.nil? || span.context.nil? || !span.context.valid?

    response.set_header("X-Trace-ID", span.context.hex_trace_id)
  end
end
