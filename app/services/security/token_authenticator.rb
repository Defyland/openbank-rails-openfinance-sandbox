module Security
  class TokenAuthenticator
    BEARER_PATTERN = /\ABearer (?<token>.+)\z/i

    def self.call!(authorization_header)
      token = bearer_token(authorization_header)
      raise AuthenticationError, "Bearer token is required." if token.blank?

      access_token = AccessToken.includes(:developer_app, :consent).find_by(token_digest: digest(token))
      raise AuthenticationError, "Invalid bearer token." if access_token.nil?
      raise AuthenticationError, "Bearer token expired or revoked." unless access_token.active?
      raise AuthenticationError, "Developer app is suspended." unless access_token.developer_app.active?

      access_token.mark_used!
      access_token
    end

    def self.bearer_token(authorization_header)
      authorization_header.to_s.match(BEARER_PATTERN)&.[](:token)
    end

    def self.digest(token)
      AccessToken.digest(token)
    end
  end
end
