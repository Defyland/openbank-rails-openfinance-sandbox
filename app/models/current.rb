class Current < ActiveSupport::CurrentAttributes
  attribute :request_id, :correlation_id, :ip_address, :user_agent, :developer_app, :access_token, :consent, :session, :user
end
