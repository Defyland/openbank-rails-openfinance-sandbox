# HTTP Examples

## Create Developer App

```bash
curl -s http://localhost:3000/v1/developer_apps \
  -H "Content-Type: application/json" \
  -d '{
    "developer_app": {
      "name": "Acme Fintech QA",
      "webhook_url": "https://partner.example.test/webhooks"
    }
  }'
```

## Create and Authorize Consent

```bash
curl -s http://localhost:3000/v1/consents \
  -H "Content-Type: application/json" \
  -H "X-Client-Id: app_xxx" \
  -H "X-Client-Secret: sk_sandbox_xxx" \
  -d '{
    "consent": {
      "customer_document_number": "11122233344",
      "permissions": [
        "ACCOUNTS_READ",
        "BALANCES_READ",
        "TRANSACTIONS_READ",
        "PAYMENTS_INITIATE",
        "WEBHOOKS_READ"
      ]
    }
  }'

curl -X PATCH http://localhost:3000/v1/consents/cns_xxx/authorize \
  -H "X-Client-Id: app_xxx" \
  -H "X-Client-Secret: sk_sandbox_xxx"
```

## Issue Token

```bash
curl -s http://localhost:3000/v1/oauth/token \
  -H "Content-Type: application/json" \
  -H "X-Client-Id: app_xxx" \
  -H "X-Client-Secret: sk_sandbox_xxx" \
  -d '{
    "token": {
      "grant_type": "client_credentials",
      "consent_id": "cns_xxx"
    }
  }'
```

## Read Accounts and Balances

```bash
curl -s http://localhost:3000/v1/accounts \
  -H "Authorization: Bearer tok_sandbox_xxx"

curl -s http://localhost:3000/v1/accounts/acc_demo_checking/balances \
  -H "Authorization: Bearer tok_sandbox_xxx"
```

## Initiate Payment

```bash
curl -s http://localhost:3000/v1/payments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer tok_sandbox_xxx" \
  -H "Idempotency-Key: payment-001" \
  -d '{
    "payment": {
      "account_id": "acc_demo_checking",
      "external_reference": "pix-001",
      "amount_cents": 25000,
      "currency": "BRL",
      "creditor_name": "Ana Lima",
      "creditor_document": "99988877766",
      "creditor_account": "0001/43210-1"
    }
  }'
```

## Replay Webhook

```bash
curl -X POST http://localhost:3000/v1/webhook_deliveries/evt_xxx/replay \
  -H "X-Client-Id: app_xxx" \
  -H "X-Client-Secret: sk_sandbox_xxx"
```
