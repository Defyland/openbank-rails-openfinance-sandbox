class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.string :action, null: false
      t.string :actor_type
      t.bigint :actor_id
      t.string :actor_identifier
      t.string :target_type
      t.bigint :target_id
      t.string :target_identifier
      t.string :request_id
      t.string :correlation_id
      t.string :ip_address
      t.string :user_agent
      t.json :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :audit_events, [ :action, :created_at ]
    add_index :audit_events, [ :actor_type, :actor_id, :created_at ]
    add_index :audit_events, [ :target_type, :target_id, :created_at ]
    add_index :audit_events, :correlation_id
  end
end
