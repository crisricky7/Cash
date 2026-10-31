# Contributing

Cash is a personal project owned and maintained by Ricardo Muñoz. Bug reports and suggestions are welcome through [GitHub issues](https://github.com/crisricky7/Cash/issues).

## Workflow

1. Open or pick an issue, and describe the expected behaviour and how to verify it.
2. Create a branch that includes the issue number, for example `6-fix-transfers`.
3. Keep commits small and use [Conventional Commits](https://www.conventionalcommits.org/) that reference the issue: `fix: escape CSV fields (#6)`.
4. Open a pull request that closes the issue: `Closes #6`.

## Before opening a pull request

- Build the backend: `dotnet build backend/src/Cash.Api`
- Analyze the app: `flutter analyze`, from `mobile/cash_app`
- Run the API tests, which need Docker: `dotnet test backend/tests/Cash.Api.Tests`
- Run the app tests: `flutter test`, from `mobile/cash_app`
- Add tests when you change behaviour.

## Data and secrets

- Never commit credentials. Settings come from `.env`, and `.env.example` documents the keys with placeholders only.
- Use clearly fake data in fixtures, screenshots and sample invoices. Never use real personal or financial data.
