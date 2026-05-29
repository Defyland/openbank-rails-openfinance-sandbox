module V1
  class TokensController < ApiController
    before_action :authenticate_client!

    def create
      token_params = params.require(:token).permit(:grant_type, :consent_id)
      raise Security::AuthorizationError, "Unsupported grant_type." unless token_params[:grant_type] == "client_credentials"

      consent = current_developer_app.consents.find_by!(external_id: token_params.fetch(:consent_id))
      access_token = Sandbox::TokenIssuer.call!(developer_app: current_developer_app, consent: consent)
      render json: { token: ApiSerializer.token(access_token) }, status: :created
    end
  end
end
