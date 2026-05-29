module Ops
  class DashboardController < BaseController
    def show
      @stats = {
        developer_apps: DeveloperApp.count,
        authorized_consents: Consent.where(status: "authorized").count,
        pending_webhooks: WebhookDelivery.where(status: "pending").count,
        failed_webhooks: WebhookDelivery.where(status: %w[failed dead]).count,
        payments_today: PaymentInitiation.where(created_at: Time.current.all_day).count,
        audit_events_today: AuditEvent.where(created_at: Time.current.all_day).count
      }
      @recent_payments = PaymentInitiation.includes(:developer_app, :account).order(created_at: :desc).limit(8)
      @recent_webhooks = WebhookDelivery.includes(:developer_app).order(created_at: :desc).limit(8)
      @recent_audit_events = AuditEvent.includes(:actor, :target).recent.limit(8)
    end
  end
end
