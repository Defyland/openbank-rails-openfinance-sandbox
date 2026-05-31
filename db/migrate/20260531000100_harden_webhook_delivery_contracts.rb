class HardenWebhookDeliveryContracts < ActiveRecord::Migration[8.1]
  def change
    add_column :developer_apps, :webhook_signing_secret_ciphertext, :text
    add_column :webhook_deliveries, :signature_timestamp, :datetime
    add_column :webhook_deliveries, :last_response_status, :integer
  end
end
