# CI comments

On pull requests the content CI workflow posts a comment with the contents of build/pre_release_check.txt.

Notes:
- runs with if: always()
- tolerates missing file (posts "pre_release_check.txt not found")
- no new dependencies

