class CreateOpenbankCore < ActiveRecord::Migration[8.1]
  def change
    create_table :developer_apps do |t|
      t.string :name, null: false
      t.string :client_id, null: false
      t.string :client_secret_digest, null: false
      t.string :webhook_url, null: false
      t.string :status, null: false, default: "active"
      t.string :active_scenario_code, null: false, default: "happy_path"
      t.integer :rate_limit_per_minute, null: false, default: 120
      t.json :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :developer_apps, :client_id, unique: true
    add_index :developer_apps, [ :status, :active_scenario_code ]

    create_table :sandbox_customers do |t|
      t.string :external_id, null: false
      t.string :document_number, null: false
      t.string :full_name, null: false
      t.string :segment, null: false, default: "retail"
      t.string :risk_profile, null: false, default: "standard"
      t.json :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :sandbox_customers, :external_id, unique: true
    add_index :sandbox_customers, :document_number, unique: true

    create_table :accounts do |t|
      t.references :sandbox_customer, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :account_type, null: false, default: "checking"
      t.string :branch_code, null: false
      t.string :number, null: false
      t.string :check_digit, null: false
      t.string :currency, null: false, default: "BRL"
      t.bigint :available_balance_cents, null: false, default: 0
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :accounts, :external_id, unique: true
    add_index :accounts, [ :sandbox_customer_id, :status ]
    add_index :accounts, [ :branch_code, :number, :check_digit ], unique: true

    create_table :ledger_transactions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :transaction_type, null: false
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, default: "BRL"
      t.string :description, null: false
      t.string :category, null: false, default: "general"
      t.datetime :posted_at, null: false
      t.json :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :ledger_transactions, [ :account_id, :external_id ], unique: true
    add_index :ledger_transactions, [ :account_id, :posted_at ]

    create_table :consents do |t|
      t.references :developer_app, null: false, foreign_key: true
      t.references :sandbox_customer, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :status, null: false, default: "awaiting_authorization"
      t.json :permissions, null: false, default: []
      t.datetime :expires_at, null: false
      t.datetime :authorized_at
      t.datetime :revoked_at
      t.string :correlation_id
      t.integer :lock_version, null: false, default: 0
      t.json :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :consents, [ :developer_app_id, :external_id ], unique: true
    add_index :consents, [ :developer_app_id, :status ]
    add_index :consents, [ :sandbox_customer_id, :status ]

    create_table :access_tokens do |t|
      t.references :developer_app, null: false, foreign_key: true
      t.references :consent, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.string :token_last_eight, null: false
      t.json :permissions, null: false, default: []
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.datetime :last_used_at
      t.timestamps
    end
    add_index :access_tokens, :token_digest, unique: true
    add_index :access_tokens, [ :developer_app_id, :expires_at ]
    add_index :access_tokens, [ :consent_id, :revoked_at ]

    create_table :payment_initiations do |t|
      t.references :developer_app, null: false, foreign_key: true
      t.references :consent, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :external_reference, null: false
      t.string :idempotency_key, null: false
      t.string :request_fingerprint, null: false
      t.string :status, null: false, default: "accepted"
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, default: "BRL"
      t.string :creditor_name, null: false
      t.string :creditor_document, null: false
      t.string :creditor_account, null: false
      t.string :failure_code
      t.string :correlation_id
      t.datetime :processed_at
      t.json :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :payment_initiations, [ :developer_app_id, :external_id ], unique: true
    add_index :payment_initiations, [ :developer_app_id, :idempotency_key ], unique: true
    add_index :payment_initiations, [ :developer_app_id, :status ]
    add_index :payment_initiations, [ :consent_id, :created_at ]

    create_table :webhook_deliveries do |t|
      t.references :developer_app, null: false, foreign_key: true
      t.string :event_id, null: false
      t.string :event_type, null: false
      t.string :aggregate_type, null: false
      t.bigint :aggregate_id, null: false
      t.string :status, null: false, default: "pending"
      t.json :payload, null: false, default: {}
      t.string :signature, null: false
      t.string :idempotency_key, null: false
      t.string :correlation_id
      t.integer :attempts_count, null: false, default: 0
      t.datetime :next_attempt_at
      t.datetime :delivered_at
      t.text :last_error
      t.timestamps
    end
    add_index :webhook_deliveries, :event_id, unique: true
    add_index :webhook_deliveries, :idempotency_key, unique: true
    add_index :webhook_deliveries, [ :developer_app_id, :status ]
    add_index :webhook_deliveries, [ :status, :next_attempt_at ]

    create_table :sandbox_scenarios do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description, null: false
      t.string :status, null: false, default: "active"
      t.json :config, null: false, default: {}
      t.timestamps
    end
    add_index :sandbox_scenarios, :code, unique: true
    add_index :sandbox_scenarios, :status

    add_check_constraint :developer_apps, "status IN ('active', 'suspended')", name: "developer_apps_status_valid"
    add_check_constraint :developer_apps, "rate_limit_per_minute > 0", name: "developer_apps_rate_limit_positive"
    add_check_constraint :accounts, "available_balance_cents >= 0", name: "accounts_balance_non_negative"
    add_check_constraint :accounts, "status IN ('active', 'blocked', 'closed')", name: "accounts_status_valid"
    add_check_constraint :accounts, "account_type IN ('checking', 'savings', 'payment')", name: "accounts_type_valid"
    add_check_constraint :ledger_transactions, "amount_cents > 0", name: "ledger_transactions_amount_positive"
    add_check_constraint :ledger_transactions, "transaction_type IN ('credit', 'debit')", name: "ledger_transactions_type_valid"
    add_check_constraint :consents,
                         "status IN ('awaiting_authorization', 'authorized', 'revoked', 'expired', 'rejected')",
                         name: "consents_status_valid"
    add_check_constraint :consents, "expires_at > created_at", name: "consents_expire_after_creation"
    add_check_constraint :consents, "lock_version >= 0", name: "consents_lock_version_non_negative"
    add_check_constraint :access_tokens, "expires_at > created_at", name: "access_tokens_expire_after_creation"
    add_check_constraint :access_tokens, "length(token_last_eight) = 8", name: "access_tokens_last_eight_length"
    add_check_constraint :payment_initiations, "amount_cents > 0", name: "payment_initiations_amount_positive"
    add_check_constraint :payment_initiations,
                         "status IN ('accepted', 'rejected', 'settled')",
                         name: "payment_initiations_status_valid"
    add_check_constraint :webhook_deliveries,
                         "status IN ('pending', 'delivered', 'failed', 'dead')",
                         name: "webhook_deliveries_status_valid"
    add_check_constraint :webhook_deliveries, "attempts_count >= 0", name: "webhook_deliveries_attempts_non_negative"
    add_check_constraint :sandbox_scenarios, "status IN ('active', 'retired')", name: "sandbox_scenarios_status_valid"
  end
end
