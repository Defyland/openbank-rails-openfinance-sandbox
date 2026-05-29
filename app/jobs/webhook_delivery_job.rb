class WebhookDeliveryJob < ApplicationJob
  queue_as :default

  def perform(webhook_delivery_id)
    WebhookDelivery.find(webhook_delivery_id).deliver!
  end
end
