module Sandbox
  class ScenarioRegistry
    DEFINITIONS = {
      "happy_path" => {
        name: "Happy path",
        description: "All consent, account, payment, and webhook flows succeed.",
        config: {}
      },
      "payment_rejected" => {
        name: "Payment rejected",
        description: "Payment initiations are accepted by the API but rejected by the simulated bank core.",
        config: { "reject_payments" => true, "failure_code" => "SCENARIO_REJECTED" }
      },
      "expired_consent" => {
        name: "Expired consent",
        description: "Authorized consents are treated as expired when a token is requested.",
        config: { "force_consent_expiry" => true }
      },
      "webhook_retry" => {
        name: "Webhook retry",
        description: "Webhook delivery attempts fail so partners can test replay and dead-letter handling.",
        config: { "force_webhook_failure" => true }
      },
      "slow_bank" => {
        name: "Slow bank",
        description: "Adds deterministic latency hints for partner timeout and retry tests.",
        config: { "latency_ms" => 250 }
      }
    }.freeze

    def self.known?(code)
      DEFINITIONS.key?(code.to_s)
    end

    def self.all
      DEFINITIONS.map do |code, definition|
        definition.merge(code: code)
      end
    end

    def self.config_for(code)
      DEFINITIONS.fetch(code.to_s, DEFINITIONS.fetch("happy_path")).fetch(:config)
    end

    def self.payment_rejected?(code)
      config_for(code)["reject_payments"] == true
    end

    def self.webhook_failure?(code)
      config_for(code)["force_webhook_failure"] == true
    end

    def self.consent_expired?(code)
      config_for(code)["force_consent_expiry"] == true
    end

    def self.failure_code(code)
      config_for(code)["failure_code"] || "SANDBOX_FAILURE"
    end

    def self.latency_ms(code)
      config_for(code)["latency_ms"].to_i
    end
  end
end
