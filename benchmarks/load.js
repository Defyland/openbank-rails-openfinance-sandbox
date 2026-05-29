import http from "k6/http";
import { check } from "k6";
import { BASE_URL, bearerHeaders, bootstrapPartnerSession, paymentPayload } from "./common.js";

export const options = {
  stages: [
    { duration: "30s", target: 10 },
    { duration: "1m", target: 10 },
    { duration: "30s", target: 0 }
  ],
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<350", "p(99)<700"]
  }
};

export function setup() {
  return bootstrapPartnerSession();
}

export default function (session) {
  const bearer = bearerHeaders(session.accessToken);

  const accounts = http.get(`${BASE_URL}/v1/accounts`, bearer);
  check(accounts, { "accounts listed": (r) => r.status === 200 });

  const balances = http.get(`${BASE_URL}/v1/accounts/${session.accountId}/balances`, bearer);
  check(balances, { "balances read": (r) => r.status === 200 });

  const payment = http.post(
    `${BASE_URL}/v1/payments`,
    JSON.stringify(paymentPayload(session.accountId, `load-${__VU}-${__ITER}-${Date.now()}`)),
    bearerHeaders(session.accessToken, { "Idempotency-Key": `load-${__VU}-${__ITER}-${Date.now()}` })
  );
  check(payment, { "payment accepted": (r) => r.status === 201 });
}
