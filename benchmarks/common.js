import http from "k6/http";
import { check, fail } from "k6";

export const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";

export function createApp() {
  const response = http.post(`${BASE_URL}/v1/developer_apps`, JSON.stringify({
    developer_app: {
      name: `k6-${Math.random()}`,
      webhook_url: "https://partner.example.test/webhooks",
      rate_limit_per_minute: Number(__ENV.RATE_LIMIT_PER_MINUTE || "50000")
    }
  }), jsonHeaders());
  if (!check(response, { "developer app created": (r) => r.status === 201 })) {
    fail(`developer app creation failed with ${response.status}: ${response.body}`);
  }
  return response.json("developer_app");
}

export function jsonHeaders(extra = {}) {
  return {
    headers: Object.assign({
      "Content-Type": "application/json",
      "X-Correlation-ID": `k6-${Date.now()}-${Math.random().toString(16).slice(2)}`
    }, extra)
  };
}

export function clientHeaders(app) {
  return jsonHeaders({
    "X-Client-Id": app.id,
    "X-Client-Secret": app.client_secret
  });
}

export function createConsent(app) {
  const response = http.post(`${BASE_URL}/v1/consents`, JSON.stringify({
    consent: {
      customer_document_number: "11122233344",
      permissions: ["ACCOUNTS_READ", "BALANCES_READ", "TRANSACTIONS_READ", "PAYMENTS_INITIATE", "WEBHOOKS_READ"]
    }
  }), clientHeaders(app));

  if (!check(response, { "consent created": (r) => r.status === 201 })) {
    fail(`consent creation failed with ${response.status}: ${response.body}`);
  }

  return response.json("consent.id");
}

export function authorizeConsent(app, consentId) {
  const response = http.patch(`${BASE_URL}/v1/consents/${consentId}/authorize`, null, clientHeaders(app));

  if (!check(response, { "consent authorized": (r) => r.status === 200 })) {
    fail(`consent authorization failed with ${response.status}: ${response.body}`);
  }
}

export function issueToken(app, consentId) {
  const response = http.post(`${BASE_URL}/v1/oauth/token`, JSON.stringify({
    token: { grant_type: "client_credentials", consent_id: consentId }
  }), clientHeaders(app));

  if (!check(response, { "token issued": (r) => r.status === 201 })) {
    fail(`token issuance failed with ${response.status}: ${response.body}`);
  }

  return response.json("token.access_token");
}

export function bearerHeaders(accessToken, extra = {}) {
  return jsonHeaders(Object.assign({ Authorization: `Bearer ${accessToken}` }, extra));
}

export function bootstrapPartnerSession() {
  const app = createApp();
  const consentId = createConsent(app);
  authorizeConsent(app, consentId);
  const accessToken = issueToken(app, consentId);

  const accounts = http.get(`${BASE_URL}/v1/accounts`, bearerHeaders(accessToken));
  if (!check(accounts, { "accounts listed": (r) => r.status === 200 })) {
    fail(`accounts listing failed with ${accounts.status}: ${accounts.body}`);
  }

  return {
    accessToken,
    accountId: accounts.json("accounts.0.id")
  };
}

export function paymentPayload(accountId, suffix) {
  return {
    payment: {
      account_id: accountId,
      external_reference: `pix-k6-${suffix}`,
      amount_cents: 100,
      currency: "BRL",
      creditor_name: "Benchmark Creditor",
      creditor_document: "99988877766",
      creditor_account: "0001/43210-1"
    }
  };
}
