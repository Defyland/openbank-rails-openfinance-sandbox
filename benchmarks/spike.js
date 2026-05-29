import http from "k6/http";
import { check } from "k6";
import { BASE_URL, bearerHeaders, bootstrapPartnerSession } from "./common.js";

export const options = {
  stages: [
    { duration: "10s", target: 5 },
    { duration: "10s", target: 50 },
    { duration: "20s", target: 50 },
    { duration: "10s", target: 0 }
  ],
  thresholds: {
    http_req_failed: ["rate<0.05"],
    http_req_duration: ["p(95)<900", "p(99)<1500"]
  }
};

export function setup() {
  return bootstrapPartnerSession();
}

export default function (session) {
  const accounts = http.get(`${BASE_URL}/v1/accounts`, bearerHeaders(session.accessToken));
  check(accounts, { "accounts listed": (r) => r.status === 200 });

  const balances = http.get(`${BASE_URL}/v1/accounts/${session.accountId}/balances`, bearerHeaders(session.accessToken));
  check(balances, { "balances read": (r) => r.status === 200 });
}
