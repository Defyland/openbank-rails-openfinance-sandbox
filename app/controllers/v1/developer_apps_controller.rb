module V1
  class DeveloperAppsController < ApiController
    before_action :authenticate_client!, only: %i[show rotate_client_secret rotate_webhook_signing_secret]

    def create
      app = DeveloperApp.create!(developer_app_params)
      AuditTrail.record!(
        action: "v1.developer_app.created",
        target: app,
        metadata: {
          webhook_url: app.webhook_url,
          rate_limit_per_minute: app.rate_limit_per_minute
        }
      )
      render json: { developer_app: ApiSerializer.developer_app(app, include_secret: true) }, status: :created
    end

    def show
      render json: { developer_app: ApiSerializer.developer_app(current_developer_app) }
    end

    def rotate_client_secret
      current_developer_app.rotate_client_secret!
      AuditTrail.record!(
        action: "v1.developer_app.client_secret_rotated",
        actor: current_developer_app,
        target: current_developer_app
      )
      render json: { developer_app: ApiSerializer.developer_app(current_developer_app, include_secret: true) }
    end

    def rotate_webhook_signing_secret
      current_developer_app.rotate_webhook_signing_secret!
      AuditTrail.record!(
        action: "v1.developer_app.webhook_signing_secret_rotated",
        actor: current_developer_app,
        target: current_developer_app
      )
      render json: { developer_app: ApiSerializer.developer_app(current_developer_app, include_secret: true) }
    end

    private

    def developer_app_params
      params.require(:developer_app).permit(:name, :webhook_url, :rate_limit_per_minute, metadata: {})
    end
  end
end
