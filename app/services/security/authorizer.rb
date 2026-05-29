module Security
  class Authorizer
    def self.require_permission!(access_token, permission)
      return if access_token.allows?(permission)

      raise AuthorizationError, "Token does not include #{permission} permission."
    end

    def self.require_same_app!(record, developer_app)
      return if record.developer_app_id == developer_app.id

      raise AuthorizationError, "Resource belongs to another client."
    end

    def self.require_consent_customer!(account, consent)
      return if account.sandbox_customer_id == consent.sandbox_customer_id

      raise AuthorizationError, "Account is outside the authorized customer consent."
    end
  end
end
