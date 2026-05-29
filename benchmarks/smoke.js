import http from "k6/http";
import { check, sleep } from "k6";
import { BASE_URL, createApp, createConsent, authorizeConsent, issueToken, bearerHeaders } from "./common.js";

export const options = {
  vus: 1,
  iterations: 1,
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<500"]
  }
};

export default function () {
  check(http.get(`${BASE_URL}/up`), { "live": (r) => r.status === 200 });
  const app = createApp();
  const consentId = createConsent(app);
  authorizeConsent(app, consentId);
  const accessToken = issueToken(app, consentId);
  const bearer = bearerHeaders(accessToken);
  check(http.get(`${BASE_URL}/v1/accounts`, bearer), { "accounts listed": (r) => r.status === 200 });
  sleep(1);
}
