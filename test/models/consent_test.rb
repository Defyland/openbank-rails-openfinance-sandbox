require "test_helper"

class ConsentTest < ActiveSupport::TestCase
  test "authorized consent requires valid permission and future expiration" do
    customer, = create_customer_with_account
    app, = create_developer_app

    consent = create_authorized_consent(app: app, customer: customer, permissions: %w[ACCOUNTS_READ BALANCES_READ])

    assert consent.active?
    assert consent.allows?("ACCOUNTS_READ")
    refute consent.allows?("PAYMENTS_INITIATE")
  end

  test "revoking consent revokes active access tokens" do
    customer, = create_customer_with_account
    app, = create_developer_app
    consent = create_authorized_consent(app: app, customer: customer)
    token = issue_token(app: app, consent: consent)

    consent.revoke!

    assert_equal "revoked", consent.status
    assert_not_nil token.reload.revoked_at
    refute token.reload.active?
  end

  test "state transitions are guarded and idempotent" do
    customer, = create_customer_with_account
    app, = create_developer_app
    consent = Consent.create!(
      developer_app: app,
      sandbox_customer: customer,
      permissions: %w[ACCOUNTS_READ],
      expires_at: 30.days.from_now
    )

    assert consent.authorize!
    refute consent.authorize!
    assert consent.revoke!
    refute consent.revoke!

    error = assert_raises(ActiveRecord::RecordInvalid) { consent.authorize! }
    assert_includes error.record.errors.full_messages.to_sentence, "cannot transition from revoked to authorized"
  end

  test "cannot revoke a consent before authorization" do
    customer, = create_customer_with_account
    app, = create_developer_app
    consent = Consent.create!(
      developer_app: app,
      sandbox_customer: customer,
      permissions: %w[ACCOUNTS_READ],
      expires_at: 30.days.from_now
    )

    error = assert_raises(ActiveRecord::RecordInvalid) { consent.revoke! }
    assert_includes error.record.errors.full_messages.to_sentence, "cannot transition from awaiting_authorization to revoked"
  end
end
