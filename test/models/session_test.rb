require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "stale sessions are detected and trimmed" do
    stale_session = Session.create!(user: users(:operator), ip_address: "127.0.0.1", user_agent: "test-agent")
    stale_session.update_column(:updated_at, 15.days.ago)

    assert stale_session.stale?
    assert_difference("Session.count", -1) { Session.trim_stale! }
  end

  test "refresh_if_needed touches old sessions" do
    session = Session.create!(user: users(:operator), ip_address: "127.0.0.1", user_agent: "test-agent")
    session.update_column(:updated_at, 10.minutes.ago)

    assert_changes -> { session.reload.updated_at.to_i } do
      session.refresh_if_needed!
    end
  end
end
