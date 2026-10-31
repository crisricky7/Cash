# Changelog

Notable changes to this project, built from the git history. The project has no tagged releases yet. Entries describe what the code does, so some differ from the original commit messages.

## Unreleased

### Added

- MIT license, README, contributing guide and this changelog.
- `.env.example`, and `.env` loading in the API through DotNetEnv.
- Configurable PostgreSQL host port in `docker-compose.yml`.

### Changed

- The database connection and JWT signing key come from the environment. The API refuses to start without them.

### Removed

- Hard-coded development credentials and their fallbacks.
- Seeded users.

## 2026-10-14

### Added

- Annual billing options for the Personal, Family and Family Plus plans in the plan selection screen. No payment is taken in the app.
- `HouseholdInvitation` and `StoryTip` domain entities, with API endpoints for invitations and stories that keep their data in memory.
- Local registration and login in the app, with a separate on-device workspace per email address that starts with empty balances.
- A four-tab layout for the app's views.

### Fixed

- Keyboard overlap in modals, and responsive padding and dropdowns across views.
- Build errors from an undefined variable and an invalid icon name.

## 2026-10-13

### Added

- Initial commit.
- .NET 10 backend with Clean Architecture layers, MediatR, JWT authentication and PostgreSQL.
- Flutter app, plus a GitHub Actions workflow that builds an Android APK.
- Flutter web build, deployed to GitHub Pages by the same workflow.
- Analytics, CSV export, savings goals, recurring bills, dark mode and a plan selection screen.
- Payphone and RevenueCat billing endpoints and a `Subscription` entity. Without a Payphone token, confirmation is simulated.
- Digital wallet accounts, account-to-wallet transfers and API endpoints for accounts and categories.
- Invoice entry from pasted SRI XML with a 15% VAT breakdown, the 50/30/20 view, family expense split and credit card installments.
