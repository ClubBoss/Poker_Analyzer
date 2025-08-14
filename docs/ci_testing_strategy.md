# CI Testing Strategy

This project uses three GitHub Actions workflows to balance coverage with fast feedback:

- **Unit Tests (PR & Push)** - runs on every pull request and push. Executes a small canary test and any tests under `test/smoke/`, excluding tests tagged with `@Tags(['slow'])`.
- **Unit Tests (Nightly Full)** - scheduled nightly to run the entire test suite with coverage.
- **Full Tests (Manual)** - can be triggered manually to run the full suite on demand.

### Adding Smoke Tests

Place quick, high-signal tests in `test/smoke/` so they run on every PR. Slower tests can stay in `test/` but should be tagged with `@Tags(['slow'])` to keep them out of PR runs.
