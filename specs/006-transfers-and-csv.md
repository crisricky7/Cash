# Spec: account transfers and CSV escaping

Issue: [#6](https://github.com/crisricky7/Cash/issues/6)
Status: Accepted

## Problem

- `POST /api/catalogs/accounts/transfer` returns 500. It saves a transaction with an empty `CategoryId`, which violates the foreign key, so no transfer can complete.
- CSV exports in the API and the app do not escape fields. A description such as `Lunch, office` adds a column.
- The API export labels transfers as `GASTO`. The app already labels them `TRANSFERENCIA`.

## Expected behaviour

### Transfers (API)

| ID | Given | When | Then |
|---|---|---|---|
| T1 | Two existing accounts and an amount above 0 | A transfer is requested | Responds 200 with both new balances, and saves the balances and one `Transfer` transaction together |
| T2 | A completed transfer | The dashboard is requested | Total balance is unchanged, and monthly income, monthly expense and category budgets do not include the transfer |
| T3 | A completed transfer | The dashboard is requested | The transfer appears in recent transactions with the category name `Transferencia` |
| T4 | An amount of 0 or less, or the same source and destination | A transfer is requested | Responds 400 and changes nothing |
| T5 | A source or destination that does not exist | A transfer is requested | Responds 404 and changes nothing |
| T6 | No valid token | A transfer is requested | Responds 401 and changes nothing |
| T7 | A source balance lower than the amount | A transfer is requested | Responds 200 and the source balance becomes negative, because accounts can represent credit cards |

### CSV (API and app)

| ID | Given | When | Then |
|---|---|---|---|
| C1 | A field containing a comma, double quote or line break | The CSV is generated | The field is wrapped in double quotes, and inner double quotes are doubled, as in RFC 4180 |
| C2 | A field without those characters | The CSV is generated | The field is written unchanged |
| C3 | A transfer | The CSV is generated | Its type is `TRANSFERENCIA` in both the API and the app |
| C4 | Any server locale (API) | The CSV is generated | Amounts use a dot as the decimal separator, for example `12.50` |

## Out of scope

- Spreadsheet formula injection (fields starting with `=`, `+`, `-` or `@`).
- Changes to the app's transfer flow, which uses local storage and does not call this endpoint.
- Running the new tests in CI, which belongs to [#2](https://github.com/crisricky7/Cash/issues/2) and [#3](https://github.com/crisricky7/Cash/issues/3).

## Technical plan

1. Make `Transaction.CategoryId` nullable, because a transfer has no category. The transfer endpoint stops sending `Guid.Empty`. The project has no migrations, so local databases must be recreated with `docker compose down -v`.
2. Show `Transferencia` for transfers in the dashboard's recent transactions.
3. Add a CSV field helper to the API export and use it for every text field. Format dates and amounts with the invariant culture, and map each transaction type to its label.
4. Move the app's CSV generation to a public top-level function with the same escaping, so tests can call it. No visible change apart from the escaping.
5. Add `backend/tests/Cash.Api.Tests` with xUnit, `WebApplicationFactory` and Testcontainers for PostgreSQL. The in-memory EF provider does not enforce foreign keys, so it could not catch this bug.
6. Add `mobile/cash_app/test/csv_test.dart`. These are pure function tests with no UI or device interaction.

## Tasks

- [ ] Write failing API tests for T1 to T7 and C1 to C4
- [ ] Fix transfers and the dashboard
- [ ] Fix the API CSV export
- [ ] Write failing app tests for C1 to C3
- [ ] Fix the app CSV export
- [ ] Update the README limitations and the changelog
