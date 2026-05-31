# Scenario Catalog

Scenarios are activated per developer app and keep partner QA deterministic.

| Code | Behavior | Primary test target |
| --- | --- | --- |
| `happy_path` | Consent, token, account, payment, and webhook flows succeed. | Baseline integration. |
| `payment_rejected` | Payment command is persisted with `rejected` status and `SCENARIO_REJECTED`. | Partner payment failure handling. |
| `expired_consent` | Token issuance expires the consent and returns forbidden. | Consent/token lifecycle handling. |
| `webhook_retry` | Webhook delivery attempts fail and schedule retries. | Retry, replay, dead-letter workflows. |
| `slow_bank` | Exposes deterministic latency metadata. | Timeout and retry behavior in partner clients. |

Activate a scenario:

```bash
curl -X PATCH http://localhost:3000/v1/scenarios/webhook_retry/activate \
  -H "X-Client-Id: app_xxx" \
  -H "X-Client-Secret: sk_sandbox_xxx"
```

The scenario registry is code-backed and seeded into `sandbox_scenarios` for discovery.
