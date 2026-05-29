# Error Format

All API errors use the same JSON envelope:

```json
{
  "error": {
    "code": "forbidden",
    "message": "Token does not include ACCOUNTS_READ permission.",
    "details": {
      "permissions": ["must be supported"]
    },
    "request_id": "req-123",
    "correlation_id": "corr-456"
  }
}
```

`details` is optional and appears mainly for validation failures.

## Standard Codes

| HTTP | Code | Meaning |
| --- | --- | --- |
| 400 | `missing_parameter` | Required request parameter or header is missing. |
| 401 | `unauthorized` | Client credentials or bearer token is missing, invalid, expired, or revoked. |
| 403 | `forbidden` | Authenticated caller lacks permission or resource scope. |
| 404 | `not_found` | Resource does not exist in the caller scope. |
| 409 | `conflict` | Unique or idempotency conflict. |
| 422 | `validation_failed` | Payload did not pass model validations. |
| 429 | `rate_limited` | Rate limit exceeded; response includes `Retry-After`. |
