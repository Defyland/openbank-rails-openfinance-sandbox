module Security
  class ClientAuthenticator
    CLIENT_ID_HEADER = "X-Client-Id"
    CLIENT_SECRET_HEADER = "X-Client-Secret"

    def self.call!(request)
      client_id = request.headers[CLIENT_ID_HEADER].to_s
      client_secret = request.headers[CLIENT_SECRET_HEADER].to_s
      raise AuthenticationError, "Client credentials are required." if client_id.blank? || client_secret.blank?

      developer_app = DeveloperApp.find_by(client_id: client_id)
      raise AuthenticationError, "Invalid client credentials." if developer_app.nil?
      raise AuthenticationError, "Developer app is suspended." unless developer_app.active?
      raise AuthenticationError, "Invalid client credentials." unless developer_app.authenticate_secret?(client_secret)

      developer_app
    end
  end
end
