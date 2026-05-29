module Ops
  class PaymentsController < BaseController
    def index
      @status = params[:status].presence
      @payments = PaymentInitiation.includes(:developer_app, :consent, :account).order(created_at: :desc)
      @payments = @payments.where(status: @status) if @status.present?
    end

    def show
      @payment = PaymentInitiation.includes(:developer_app, :consent, :account).find(params[:id])
      @webhook_deliveries = WebhookDelivery.where(
        aggregate_type: "PaymentInitiation",
        aggregate_id: @payment.id
      ).order(created_at: :desc)
    end
  end
end
