module Ops
  class AuditEventsController < BaseController
    def index
      @actions = AuditEvent.distinct.order(:action).pluck(:action)
      @selected_action = params[:action_name].presence
      @audit_events = AuditEvent.includes(:actor, :target).recent.limit(200)
      @audit_events = @audit_events.where(action: @selected_action) if @selected_action.present?
    end

    def show
      @audit_event = AuditEvent.find(params[:id])
    end
  end
end
