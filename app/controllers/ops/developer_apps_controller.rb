module Ops
  class DeveloperAppsController < BaseController
    def index
      @developer_apps = DeveloperApp.order(created_at: :desc)
    end

    def show
      @developer_app = DeveloperApp.find(params[:id])
      @consents = @developer_app.consents.includes(:sandbox_customer).order(created_at: :desc).limit(20)
      @webhook_deliveries = @developer_app.webhook_deliveries.order(created_at: :desc).limit(20)
    end
  end
end
