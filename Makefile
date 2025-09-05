.PHONY: allowlists allowlists-sync allowlists-check images gap beta beta-zip check fix-terms beta-fix beta-fix-continue pre-release research-check ui-assets discover ascii-check gap-details ascii-fix demos-steps demo-token-tag demos-steps-fix theory-fix
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
