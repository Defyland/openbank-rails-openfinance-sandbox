module Ops
  class ScenariosController < BaseController
    def index
      @developer_apps = DeveloperApp.order(:name)
      @scenarios = Sandbox::ScenarioRegistry.all
    end

    def activate
      developer_app = DeveloperApp.find(params.require(:developer_app_id))
      scenario_code = params[:id]
      raise ActiveRecord::RecordNotFound unless Sandbox::ScenarioRegistry.known?(scenario_code)

      developer_app.update!(active_scenario_code: scenario_code)
      AuditTrail.record!(
        action: "ops.scenario.activated",
        actor: Current.user,
        target: developer_app,
        metadata: { scenario_code: scenario_code }
      )
      redirect_to ops_scenarios_path, notice: "#{scenario_code} activated for #{developer_app.name}."
    end
  end
end
