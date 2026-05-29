module V1
  class ScenariosController < ApiController
    before_action :authenticate_client!

    def index
      render json: {
        active_scenario_code: current_developer_app.active_scenario_code,
        scenarios: Sandbox::ScenarioRegistry.all.map { |definition| ApiSerializer.scenario(definition) }
      }
    end

    def activate
      raise ActiveRecord::RecordNotFound unless Sandbox::ScenarioRegistry.known?(params[:code])

      current_developer_app.update!(active_scenario_code: params[:code])
      AuditTrail.record!(
        action: "v1.scenario.activated",
        actor: current_developer_app,
        target: current_developer_app,
        metadata: { scenario_code: params[:code] }
      )
      render json: { developer_app: ApiSerializer.developer_app(current_developer_app) }
    end
  end
end
