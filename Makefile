.PHONY: allowlists allowlists-sync allowlists-check images gap beta beta-zip check fix-terms beta-fix beta-fix-continue pre-release research-check ui-assets discover ascii-check gap-details ascii-fix demos-steps demo-token-tag demos-steps-fix demos-count-fix theory-fix wordcount-balance drills-fix drills-seed
allowlists:
	@dart run tooling/derive_allowlists.dart --write --clear
allowlists-sync:
	python3 tools/allowlists_sync.py --write

allowlists-check:
	python3 tools/allowlists_sync.py --check

# Generate/refresh image specs, render stub SVGs, and insert links.
images:
	dart run tooling/gen_image_specs.dart && \
	dart run tooling/render_images_stub.dart && \
	dart run tooling/link_images_in_theory.dart

# Create gaps.json and print the GAP table + TOP GAPS footer.
gap:
	mkdir -p build && \
	dart run tooling/content_gap_report.dart --json build/gaps.json

# Convenience target: run images then gap.
beta:
	$(MAKE) images && $(MAKE) gap

# Optional local pack: zip content/ after beta.
beta-zip:
	mkdir -p build && \
	zip -qr build/beta_content.zip content

# Quick content GAP table (no JSON file write)
check:
	@dart run tooling/content_gap_report.dart

# Apply terminology fixes and confirm clean lint
fix-terms:
	dart run tooling/term_lint.dart --fix --fix-scope=md+jsonl && \
	dart run tooling/term_lint.dart --quiet

# One-command pass: fix terms, refresh images/links, write artifacts
beta-fix:
	$(MAKE) fix-terms && \
	dart run tooling/gen_image_specs.dart && \
	dart run tooling/render_images_stub.dart && \
	dart run tooling/link_images_in_theory.dart && \
	mkdir -p build && \
	dart run tooling/content_gap_report.dart --json build/gaps.json && \
	dart run tooling/term_lint.dart --json build/term_lint.json --quiet

# Non-failing convenience target: runs all steps and ignores errors
beta-fix-continue:
	- dart run tooling/term_lint.dart --fix --fix-scope=md+jsonl
	- dart run tooling/gen_image_specs.dart
	- dart run tooling/render_images_stub.dart
	- dart run tooling/link_images_in_theory.dart
	- mkdir -p build
	- dart run tooling/content_gap_report.dart --json build/gaps.json
	- dart run tooling/term_lint.dart --json build/term_lint.json --quiet
	- zip -qr build/beta_content.zip content

# Aggregate gates and print PASS/FAIL summary
pre-release:
	@dart run tooling/pre_release_check.dart

# Validate a draft content folder (outside repo)
research-check:
	@test -n "$(DRAFT)" || { echo "Set DRAFT=/abs/path"; exit 2; }
	@mkdir -p build
	@dart run tooling/research_quickcheck.dart "$(DRAFT)" --json build/research_gaps.json

# Export compact UI assets bundle
ui-assets:
	@dart run tooling/export_ui_assets.dart --out build/ui_assets
	@ls -l build/ui_assets

# Build lesson flow JSON for UI
ui-flow:
	@dart run tooling/export_lesson_flow.dart
	@head -n 40 build/lesson_flow.json

# Build spaced-repetition review plan JSON for UI
ui-plan:
	@dart run tooling/export_review_plan.dart
	@head -n 40 build/review_plan.json

# Build search index + see-also + link blocks + export UI assets
discover:
	@mkdir -p build
	@dart run tooling/build_search_index.dart --json build/search_index.json
	@dart run tooling/build_see_also.dart --json build/see_also.json
	@dart run tooling/link_see_also_in_theory.dart
	@dart run tooling/export_ui_assets.dart --out build/ui_assets

ascii-check:
	@dart run tooling/ascii_sanitize.dart --check

gap-details:
	@mkdir -p build
	@dart run tooling/explain_gap_details.dart --json build/gap_details.json
	@wc -c build/gap_details.json

ascii-fix:
	@dart run tooling/ascii_sanitize.dart --fix
	@$(MAKE) fix-terms
	@$(MAKE) beta

# Lint demo steps and write JSON artifact
demos-steps:
	@mkdir -p build
	@dart run tooling/demos_steps_lint.dart --json build/demos_steps.json
	@wc -c build/demos_steps.json

# Tag demo tokens and refresh GAP report
demo-token-tag:
	@dart run tooling/demos_token_tag_helper.dart --fix
	@dart run tooling/content_gap_report.dart --json build/gaps.json

# Auto-append a safe 4th step to short demos, then refresh reports
demos-steps-fix:
	@mkdir -p build
	@dart run tooling/demos_steps_fix.dart --fix && \
		dart run tooling/demos_steps_lint.dart --json build/demos_steps.json --quiet && \
		dart run tooling/content_gap_report.dart --json build/gaps.json && \
		dart run tooling/explain_gap_details.dart --json build/gap_details.json

demos-count-fix:
	@dart run tooling/demos_count_fix.dart --fix && \
		dart run tooling/content_gap_report.dart --json build/gaps.json && \
		dart run tooling/explain_gap_details.dart --json build/gap_details.json

wordcount-balance:
	@dart run tooling/theory_wordcount_balance.dart --fix
	@dart run tooling/content_gap_report.dart --json build/gaps.json

wordcount-balance-agg:
	@dart run tooling/theory_wordcount_balance.dart --fix --force --aggressive
	@dart run tooling/content_gap_report.dart --json build/gaps.json

# Scaffold missing theory.md headers and first image, then refresh image pipeline and gaps
theory-fix:
	@mkdir -p build
	@dart run tooling/theory_scaffold_fix.dart --fix && \
	dart run tooling/ascii_sanitize.dart --fix && \
		dart run tooling/gen_image_specs.dart && \
		dart run tooling/render_images_stub.dart && \
		dart run tooling/link_images_in_theory.dart && \
		dart run tooling/sync_image_status.dart && \
		dart run tooling/content_gap_report.dart --json build/gaps.json

# Repair drills.jsonl issues and refresh gaps
drills-fix:
	@dart run tooling/drills_json_repair.dart --fix
	@dart run tooling/drills_count_fix.dart --module program_catalog --fix || true
	@dart run tooling/content_gap_report.dart --json build/gaps.json

# Seed minimal drills.jsonl for modules that lack it, then refresh gaps
drills-seed:
	@dart run tooling/drills_seed_missing.dart --write && \
		dart run tooling/content_gap_report.dart --json build/gaps.json

# Local test shortcuts
.PHONY: test-lite test-skip
test-lite:
	@dart test -r expanded --concurrency=1 --timeout=60s test/curriculum_status_test.dart

test-skip:
	@echo "Tests skipped on purpose"

# Prove no flutter test is present in CI configs
.PHONY: test-assert-no-flutter
test-assert-no-flutter:
	@! git grep -n "flutter test" .github/workflows Makefile || (echo "flutter test found"; exit 1)

# Lint i18n quality (fails on errors)
ui-i18n-lint:
	@dart run tooling/i18n_lint.dart
	@head -n 60 build/i18n_lint.json

# Export telemetry schema for UI logging
ui-telemetry:
	@dart run tooling/export_telemetry_schema.dart
	@head -n 60 build/telemetry_schema.json

# Export UI i18n strings (EN/RU)
ui-i18n:
	@dart run tooling/export_i18n_strings.dart --out build/i18n
	@head -n 40 build/i18n/en.json
