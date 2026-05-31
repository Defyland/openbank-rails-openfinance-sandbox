# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_31_000100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "access_tokens", force: :cascade do |t|
    t.bigint "consent_id", null: false
    t.datetime "created_at", null: false
    t.bigint "developer_app_id", null: false
    t.datetime "expires_at", null: false
    t.datetime "last_used_at"
    t.json "permissions", default: [], null: false
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.string "token_last_eight", null: false
    t.datetime "updated_at", null: false
    t.index ["consent_id", "revoked_at"], name: "index_access_tokens_on_consent_id_and_revoked_at"
    t.index ["consent_id"], name: "index_access_tokens_on_consent_id"
    t.index ["developer_app_id", "expires_at"], name: "index_access_tokens_on_developer_app_id_and_expires_at"
    t.index ["developer_app_id"], name: "index_access_tokens_on_developer_app_id"
    t.index ["token_digest"], name: "index_access_tokens_on_token_digest", unique: true
    t.check_constraint "expires_at > created_at", name: "access_tokens_expire_after_creation"
    t.check_constraint "length(token_last_eight::text) = 8", name: "access_tokens_last_eight_length"
  end

  create_table "accounts", force: :cascade do |t|
    t.string "account_type", default: "checking", null: false
    t.bigint "available_balance_cents", default: 0, null: false
    t.string "branch_code", null: false
    t.string "check_digit", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "BRL", null: false
    t.string "external_id", null: false
    t.string "number", null: false
    t.bigint "sandbox_customer_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_code", "number", "check_digit"], name: "index_accounts_on_branch_code_and_number_and_check_digit", unique: true
    t.index ["external_id"], name: "index_accounts_on_external_id", unique: true
    t.index ["sandbox_customer_id", "status"], name: "index_accounts_on_sandbox_customer_id_and_status"
    t.index ["sandbox_customer_id"], name: "index_accounts_on_sandbox_customer_id"
    t.check_constraint "account_type::text = ANY (ARRAY['checking'::character varying::text, 'savings'::character varying::text, 'payment'::character varying::text])", name: "accounts_type_valid"
    t.check_constraint "available_balance_cents >= 0", name: "accounts_balance_non_negative"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'blocked'::character varying::text, 'closed'::character varying::text])", name: "accounts_status_valid"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_events", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id"
    t.string "actor_identifier"
    t.string "actor_type"
    t.string "correlation_id"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.json "metadata", default: {}, null: false
    t.string "request_id"
    t.bigint "target_id"
    t.string "target_identifier"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["action", "created_at"], name: "index_audit_events_on_action_and_created_at"
    t.index ["actor_type", "actor_id", "created_at"], name: "index_audit_events_on_actor_type_and_actor_id_and_created_at"
    t.index ["correlation_id"], name: "index_audit_events_on_correlation_id"
    t.index ["target_type", "target_id", "created_at"], name: "index_audit_events_on_target_type_and_target_id_and_created_at"
  end

  create_table "consents", force: :cascade do |t|
    t.datetime "authorized_at"
    t.string "correlation_id"
    t.datetime "created_at", null: false
    t.bigint "developer_app_id", null: false
    t.datetime "expires_at", null: false
    t.string "external_id", null: false
    t.integer "lock_version", default: 0, null: false
    t.json "metadata", default: {}, null: false
    t.json "permissions", default: [], null: false
    t.datetime "revoked_at"
    t.bigint "sandbox_customer_id", null: false
    t.string "status", default: "awaiting_authorization", null: false
    t.datetime "updated_at", null: false
    t.index ["developer_app_id", "external_id"], name: "index_consents_on_developer_app_id_and_external_id", unique: true
    t.index ["developer_app_id", "status"], name: "index_consents_on_developer_app_id_and_status"
    t.index ["developer_app_id"], name: "index_consents_on_developer_app_id"
    t.index ["sandbox_customer_id", "status"], name: "index_consents_on_sandbox_customer_id_and_status"
    t.index ["sandbox_customer_id"], name: "index_consents_on_sandbox_customer_id"
    t.check_constraint "expires_at > created_at", name: "consents_expire_after_creation"
    t.check_constraint "lock_version >= 0", name: "consents_lock_version_non_negative"
    t.check_constraint "status::text = ANY (ARRAY['awaiting_authorization'::character varying::text, 'authorized'::character varying::text, 'revoked'::character varying::text, 'expired'::character varying::text, 'rejected'::character varying::text])", name: "consents_status_valid"
  end

  create_table "developer_apps", force: :cascade do |t|
    t.string "active_scenario_code", default: "happy_path", null: false
    t.string "client_id", null: false
    t.string "client_secret_digest", null: false
    t.datetime "created_at", null: false
    t.json "metadata", default: {}, null: false
    t.string "name", null: false
    t.integer "rate_limit_per_minute", default: 120, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.text "webhook_signing_secret_ciphertext"
    t.string "webhook_url", null: false
    t.index ["client_id"], name: "index_developer_apps_on_client_id", unique: true
    t.index ["status", "active_scenario_code"], name: "index_developer_apps_on_status_and_active_scenario_code"
    t.check_constraint "rate_limit_per_minute > 0", name: "developer_apps_rate_limit_positive"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'suspended'::character varying::text])", name: "developer_apps_status_valid"
  end

  create_table "ledger_transactions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "amount_cents", null: false
    t.string "category", default: "general", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "BRL", null: false
    t.string "description", null: false
    t.string "external_id", null: false
    t.json "metadata", default: {}, null: false
    t.datetime "posted_at", null: false
    t.string "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "external_id"], name: "index_ledger_transactions_on_account_id_and_external_id", unique: true
    t.index ["account_id", "posted_at"], name: "index_ledger_transactions_on_account_id_and_posted_at"
    t.index ["account_id"], name: "index_ledger_transactions_on_account_id"
    t.check_constraint "amount_cents > 0", name: "ledger_transactions_amount_positive"
    t.check_constraint "transaction_type::text = ANY (ARRAY['credit'::character varying::text, 'debit'::character varying::text])", name: "ledger_transactions_type_valid"
  end

  create_table "payment_initiations", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "amount_cents", null: false
    t.bigint "consent_id", null: false
    t.string "correlation_id"
    t.datetime "created_at", null: false
    t.string "creditor_account", null: false
    t.string "creditor_document", null: false
    t.string "creditor_name", null: false
    t.string "currency", default: "BRL", null: false
    t.bigint "developer_app_id", null: false
    t.string "external_id", null: false
    t.string "external_reference", null: false
    t.string "failure_code"
    t.string "idempotency_key", null: false
    t.json "metadata", default: {}, null: false
    t.datetime "processed_at"
    t.string "request_fingerprint", null: false
    t.string "status", default: "accepted", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_payment_initiations_on_account_id"
    t.index ["consent_id", "created_at"], name: "index_payment_initiations_on_consent_id_and_created_at"
    t.index ["consent_id"], name: "index_payment_initiations_on_consent_id"
    t.index ["developer_app_id", "external_id"], name: "index_payment_initiations_on_developer_app_id_and_external_id", unique: true
    t.index ["developer_app_id", "idempotency_key"], name: "idx_on_developer_app_id_idempotency_key_8e094fd266", unique: true
    t.index ["developer_app_id", "status"], name: "index_payment_initiations_on_developer_app_id_and_status"
    t.index ["developer_app_id"], name: "index_payment_initiations_on_developer_app_id"
    t.check_constraint "amount_cents > 0", name: "payment_initiations_amount_positive"
    t.check_constraint "status::text = ANY (ARRAY['accepted'::character varying::text, 'rejected'::character varying::text, 'settled'::character varying::text])", name: "payment_initiations_status_valid"
  end

  create_table "sandbox_customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "document_number", null: false
    t.string "external_id", null: false
    t.string "full_name", null: false
    t.json "metadata", default: {}, null: false
    t.string "risk_profile", default: "standard", null: false
    t.string "segment", default: "retail", null: false
    t.datetime "updated_at", null: false
    t.index ["document_number"], name: "index_sandbox_customers_on_document_number", unique: true
    t.index ["external_id"], name: "index_sandbox_customers_on_external_id", unique: true
  end

  create_table "sandbox_scenarios", force: :cascade do |t|
    t.string "code", null: false
    t.json "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_sandbox_scenarios_on_code", unique: true
    t.index ["status"], name: "index_sandbox_scenarios_on_status"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'retired'::character varying::text])", name: "sandbox_scenarios_status_valid"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_sessions_on_created_at"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.bigint "aggregate_id", null: false
    t.string "aggregate_type", null: false
    t.integer "attempts_count", default: 0, null: false
    t.string "correlation_id"
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.bigint "developer_app_id", null: false
    t.string "event_id", null: false
    t.string "event_type", null: false
    t.string "idempotency_key", null: false
    t.text "last_error"
    t.integer "last_response_status"
    t.datetime "next_attempt_at"
    t.json "payload", default: {}, null: false
    t.string "signature", null: false
    t.datetime "signature_timestamp"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["developer_app_id", "status"], name: "index_webhook_deliveries_on_developer_app_id_and_status"
    t.index ["developer_app_id"], name: "index_webhook_deliveries_on_developer_app_id"
    t.index ["event_id"], name: "index_webhook_deliveries_on_event_id", unique: true
    t.index ["idempotency_key"], name: "index_webhook_deliveries_on_idempotency_key", unique: true
    t.index ["status", "next_attempt_at"], name: "index_webhook_deliveries_on_status_and_next_attempt_at"
    t.check_constraint "attempts_count >= 0", name: "webhook_deliveries_attempts_non_negative"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'delivered'::character varying::text, 'failed'::character varying::text, 'dead'::character varying::text])", name: "webhook_deliveries_status_valid"
  end

  add_foreign_key "access_tokens", "consents"
  add_foreign_key "access_tokens", "developer_apps"
  add_foreign_key "accounts", "sandbox_customers"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "consents", "developer_apps"
  add_foreign_key "consents", "sandbox_customers"
  add_foreign_key "ledger_transactions", "accounts"
  add_foreign_key "payment_initiations", "accounts"
  add_foreign_key "payment_initiations", "consents"
  add_foreign_key "payment_initiations", "developer_apps"
  add_foreign_key "sessions", "users"
  add_foreign_key "webhook_deliveries", "developer_apps"
end
