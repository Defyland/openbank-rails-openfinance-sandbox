module V1
  class WebhookDeliveriesController < ApiController
    before_action :authenticate_client!

    def index
      deliveries = current_developer_app.webhook_deliveries.order(created_at: :desc).limit(100)
      render json: { webhook_deliveries: deliveries.map { |delivery| ApiSerializer.webhook_delivery(delivery) } }
    end

    def show
      render json: { webhook_delivery: ApiSerializer.webhook_delivery(find_delivery) }
    end

    def replay
      delivery = find_delivery
      delivery.replay!
      AuditTrail.record!(
        action: "v1.webhook_delivery.replayed",
        actor: current_developer_app,
        target: delivery,
        metadata: { status: delivery.status, attempts_count: delivery.attempts_count }
      )
      render json: { webhook_delivery: ApiSerializer.webhook_delivery(delivery.reload) }
    end

    private

    def find_delivery
      current_developer_app.webhook_deliveries.find_by!(event_id: params[:id])
    end
  end
end
