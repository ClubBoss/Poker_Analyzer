Pre-commit Hook Setup

To run fast local checks before each commit, install a Git pre-commit hook that invokes the Dart precommit runner.

Steps:

1) Create `.git/hooks/pre-commit` with the following contents:

```
#!/usr/bin/env bash
set -e
dart run tool/precommit.dart
```

2) Make it executable:

```
chmod +x .git/hooks/pre-commit
```

That's it. The hook will print concise results:

- `FAST_LIVE: PASS/FAIL`
- `FAST_CONTENT: PASS/FAIL`

Commit aborts if any check fails.
