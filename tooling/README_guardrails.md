# build/ guard

CI fails if any file under build/ is tracked.

To fix locally:
- git rm -r --cached build
- ensure .gitignore has build/ (it already does)
