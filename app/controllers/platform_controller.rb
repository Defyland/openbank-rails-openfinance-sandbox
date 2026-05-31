class PlatformController < ApiController
  skip_before_action :enforce_rate_limit!

  def live
    render json: { status: "ok", service: "openbank-sandbox", checked_at: Time.current.iso8601 }
  end

  def ready
    readiness_dependencies = {
      primary_database: connection_ready?(ActiveRecord::Base),
      cache_database: connection_ready?(SolidCache::Entry),
      queue_database: connection_ready?(SolidQueue::Job),
      cable_database: connection_ready?(SolidCable::Message)
    }

    render json: readiness_payload(readiness_dependencies),
           status: readiness_dependencies.values.all? ? :ok : :service_unavailable
  rescue ActiveRecord::ActiveRecordError => error
    Rails.logger.warn(
      message: "readiness_check_failed",
      error_class: error.class.name,
      error_message: error.message
    )

    render json: readiness_payload(
      primary_database: false,
      cache_database: false,
      queue_database: false,
      cable_database: false
    ), status: :service_unavailable
  end

  def metrics
    render plain: [
      "# HELP openbank_developer_apps_total Total sandbox developer applications.",
      "# TYPE openbank_developer_apps_total gauge",
      "openbank_developer_apps_total #{DeveloperApp.count}",
      "# HELP openbank_authorized_consents_total Authorized consents.",
      "# TYPE openbank_authorized_consents_total gauge",
      "openbank_authorized_consents_total #{Consent.where(status: 'authorized').count}",
      "# HELP openbank_webhook_deliveries_pending Pending webhook deliveries.",
      "# TYPE openbank_webhook_deliveries_pending gauge",
      "openbank_webhook_deliveries_pending #{WebhookDelivery.where(status: 'pending').count}"
    ].join("\n")
  end

  private

  def connection_ready?(klass)
    klass.connection.execute("SELECT 1")
    true
  rescue StandardError
    false
  end

  def readiness_payload(dependencies)
    {
      status: dependencies.values.all? ? "ready" : "not_ready",
      dependencies: dependencies.transform_values { |value| value ? "ok" : "error" },
      checked_at: Time.current.iso8601
    }
  end
end
