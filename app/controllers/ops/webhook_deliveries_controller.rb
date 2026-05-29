module Ops
  class WebhookDeliveriesController < BaseController
    def index
      @status = params[:status].presence
      @webhook_deliveries = WebhookDelivery.includes(:developer_app).order(created_at: :desc)
      @webhook_deliveries = @webhook_deliveries.where(status: @status) if @status.present?
    end

    def show
      @webhook_delivery = WebhookDelivery.includes(:developer_app).find(params[:id])
    end

    def replay
      delivery = WebhookDelivery.find(params[:id])
      delivery.replay!
      AuditTrail.record!(
        action: "ops.webhook_delivery.replayed",
        actor: Current.user,
        target: delivery,
        metadata: { status: delivery.status, attempts_count: delivery.attempts_count }
      )
      redirect_to ops_webhook_delivery_path(delivery), notice: "Webhook replay enqueued."
    end
  end
end
