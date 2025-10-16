# Bulk Transfer Processor

## Overview

This service receives bulk transfer requests for one bank account. It checks all the data and saves transfers in the SQLite database. It makes sure that:

- The account exists and has enough money for all the transfers.
- Each transfer is correct (amount is positive, proper format, etc.).
- Database operations are safe, no partial update if something fails.

For small projects (one server, SQLite) it processes requests directly, one by one.

---

## OpenAPI

The OpenAPI specification can be found in /doc/openapi.yaml

---

## How to run tests

1. Build the tables:
```bash
rails db:test:prepare
```
2. Run the tests
```bash
rspec
```

---

## How to run

1. Install gems:

```bash
bundle install
```

2. Database

The database already exists in /db/development.sqlite

3. Start the server:
```bash
rails s
```

4. Example request:
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "organization_bic": "BIC",
    "organization_iban": "IBAN",
    "credit_transfers": [
      {
        "amount": "14.5",
        "currency": "EUR",
        "counterparty_name": "Bip Bip",
        "counterparty_bic": "BIC1",
        "counterparty_iban": "IBAN1",
        "description": "Description1"
      }
    ]
  }' \
  http://localhost:3000/api/v1/transfers/bulk

```

## Possible improvements

### Big scale
 
Use async processing with queuing and jobs, this allows us to handle retries and peak hours of the day much better.

### Logging and metrics
There's currently no error (or debug) logging or metrics, this must be present in production

### Error response
Error responses should have both a good description and error codes available for frontend to do actions over them

### Database
SQLite is ok for small project, but this must be changed to a database like Postgres if we want to scale it