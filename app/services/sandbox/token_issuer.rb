module Sandbox
  class TokenIssuer
    def self.call!(developer_app:, consent:)
      Security::Authorizer.require_same_app!(consent, developer_app)

      if ScenarioRegistry.consent_expired?(developer_app.active_scenario_code)
        consent.expire!
        raise Security::AuthorizationError, "Consent expired by active sandbox scenario."
      end

      AccessToken.issue!(developer_app: developer_app, consent: consent)
    end
  end
end
