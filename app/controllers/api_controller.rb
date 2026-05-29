class ApiController < ActionController::API
  before_action :assign_request_context
  before_action :enforce_rate_limit!
  after_action :set_observability_headers

  rescue_from ActionController::ParameterMissing do |error|
    render_error(code: "missing_parameter", message: error.message, status: :bad_request)
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    render_error(
      code: "validation_failed",
      message: error.record.errors.full_messages.to_sentence,
      status: :unprocessable_entity,
      details: error.record.errors.to_hash(true)
    )
  end

  rescue_from ActiveRecord::RecordNotUnique do |_error|
    render_error(
      code: "conflict",
      message: "The request conflicts with an existing record.",
      status: :conflict
    )
  end

  rescue_from ActiveRecord::RecordNotFound do |_error|
    render_error(code: "not_found", message: "The requested resource was not found.", status: :not_found)
  end

  rescue_from Security::AuthenticationError do |error|
    render_error(code: "unauthorized", message: error.message, status: :unauthorized)
  end

  rescue_from Security::AuthorizationError do |error|
    render_error(code: "forbidden", message: error.message, status: :forbidden)
  end

  rescue_from Security::RateLimitExceeded do |error|
    response.set_header("Retry-After", error.retry_after.to_s)
    render_error(code: "rate_limited", message: "Rate limit exceeded. Retry later.", status: :too_many_requests)
  end

  private

  def assign_request_context
    Current.request_id = request.request_id
    Current.correlation_id = request.headers["X-Correlation-ID"].presence || request.request_id
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
  end

  def authenticate_client!
    Current.developer_app = Security::ClientAuthenticator.call!(request)
  end

  def authenticate_token!(permission = nil)
    Current.access_token = Security::TokenAuthenticator.call!(request.authorization)
    Current.developer_app = Current.access_token.developer_app
    Current.consent = Current.access_token.consent
    Security::Authorizer.require_permission!(Current.access_token, permission) if permission.present?
  end

  def current_developer_app
    Current.developer_app
  end

  def current_consent
    Current.consent
  end

  def render_error(code:, message:, status:, details: nil)
    render json: {
      error: {
        code: code,
        message: message,
        details: details,
        request_id: Current.request_id || request.request_id,
        correlation_id: Current.correlation_id
      }.compact
    }, status: status
  end

  def enforce_rate_limit!
    app = current_rate_limit_app
    key = app ? "client:#{app.client_id}" : "ip:#{request.remote_ip}"
    limit = app&.rate_limit_per_minute || 60
    Security::RateLimiter.check!(key: key, limit: limit)
  end

  def current_rate_limit_app
    client_id = request.headers[Security::ClientAuthenticator::CLIENT_ID_HEADER]
    return DeveloperApp.find_by(client_id: client_id) if client_id.present?

    token = Security::TokenAuthenticator.bearer_token(request.authorization)
    return if token.blank?

    AccessToken.includes(:developer_app).find_by(token_digest: AccessToken.digest(token))&.developer_app
  end

  def set_observability_headers
    response.set_header("X-Request-ID", Current.request_id || request.request_id)
    response.set_header("X-Correlation-ID", Current.correlation_id) if Current.correlation_id.present?

    span = OpenTelemetry::Trace.current_span
    return if span.nil? || span.context.nil? || !span.context.valid?

    response.set_header("X-Trace-ID", span.context.hex_trace_id)
  end
end
