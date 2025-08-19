name: L2 Tests (conditional)

on:
  pull_request:
  push:
    branches: [ main ]
  schedule:
    - cron: '0 1 * * *' # nightly (UTC)

concurrency:
  group: l2-tests-${{ github.event.pull_request.number || github.sha }}
  cancel-in-progress: true

jobs:
  l2:
    # Запускаем ТОЛЬКО когда явно просим:
    # - PR с лейблом 'full-ci', ИЛИ
    # - push в main с маркером '[full-ci]' в сообщении коммита, ИЛИ
    # - nightly cron
    if: ${{ (github.event_name == 'pull_request' && contains(join(github.event.pull_request.labels.*.name, ','), 'full-ci')) || (github.event_name == 'push' && contains(github.event.head_commit.message, '[full-ci]')) || github.event_name == 'schedule' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Запускаем тесты только если есть релевантные изменения
      - name: Detect relevant changes
        id: filter
        uses: dorny/paths-filter@v3
        with:
          filters: |
            l2:
              - 'assets/packs/l2/**'
              - 'assets/packs/l3/**'
              - 'assets/packs/l3/demo/**'
              - 'assets/theory/**'
              - 'tool/l3/**'
              - 'tool/config/weights/**'
              - 'tool/validators/**'
              - 'tool/validators/l3_demo_validator.dart'
              - 'tool/metrics/**'
              - 'tool/autogen/**'
              - 'tool/autogen/l3_demo_sampler.dart'
              - 'test/l2_*.dart'
              - 'test/l3_*.dart'
              - 'test/l3_demo_*.dart'
              - 'pubspec.*'

      - name: Skip (no relevant L2 changes)
        if: steps.filter.outputs.l2 != 'true'
        run: echo "No relevant L2 changes — skipping." && exit 0

      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          flutter-version: '3.27.0'
          cache: true

      - run: flutter --version
      - run: dart --version

      - name: Cache pub
        uses: actions/cache@v4
        with:
          path: ~/.pub-cache
          key: pub-${{ runner.os }}-${{ hashFiles('**/pubspec.lock') }}
          restore-keys: |
            pub-${{ runner.os }}-

      - run: flutter pub get

      - name: Precommit sanity (dup checks)
        run: bash tool/dev/precommit_sanity.sh

      - name: Check L2 theory snippet coverage
        run: dart run tool/validators/theory_snippet_coverage.dart --packs assets/packs/l2 --snippets assets/theory/l2/snippets.yaml --min 0.90

      - name: Generate L2 packs (seed 111)
        run: dart run tool/autogen/l2_pack_generator.dart --preset all --seed 111 --out build/tmp/l2/111

      - name: Generate L2 packs (seed 222)
        run: dart run tool/autogen/l2_pack_generator.dart --preset all --seed 222 --out build/tmp/l2/222

      - name: Generate L2 packs (seed 333)
        run: dart run tool/autogen/l2_pack_generator.dart --preset all --seed 333 --out build/tmp/l2/333

      - name: Validate presets
        run: dart run tool/validators/preset_validator.dart --dir build/tmp/l2

      - name: Run L2 tests
        run: flutter test -r expanded test/l2_*

      - name: Generate L3 boards (seed 111)
        timeout-minutes: 5
        run: dart run tool/autogen/l3_board_generator.dart --preset all --seed 111 --out build/tmp/l3/111 --maxAttemptsPerSpot 5000 --timeoutSec 90

      - name: Generate L3 boards (seed 222)
        timeout-minutes: 5
        run: dart run tool/autogen/l3_board_generator.dart --preset all --seed 222 --out build/tmp/l3/222 --maxAttemptsPerSpot 5000 --timeoutSec 90

      - name: Generate L3 boards (seed 333)
        timeout-minutes: 5
        run: dart run tool/autogen/l3_board_generator.dart --preset all --seed 333 --out build/tmp/l3/333 --maxAttemptsPerSpot 5000 --timeoutSec 90

      - name: Validate L3 distribution
        timeout-minutes: 5
        run: dart run tool/validators/l3_distribution_validator.dart --dir build/tmp/l3 --dedupe flop

      - name: Generate L3 demo packs
        run: dart run tool/autogen/l3_demo_sampler.dart --source build/tmp/l3/111 --preset all --out assets/packs/l3/demo --spots 100 --dedupe flop --seed 111

      - name: Validate L3 demo packs
        run: dart run tool/validators/l3_demo_validator.dart --dir assets/packs/l3/demo --dedupe flop

      - name: Generate packs manifest
        run: dart run tool/metrics/packs_manifest.dart --roots assets/packs/l2,assets/packs/l3 --out build/reports/packs_manifest.json --mdOut build/reports/packs_manifest.md

      - run: |
          echo "::group::Packs Manifest"
          cat build/reports/packs_manifest.md
          echo "::endgroup::"

      - uses: actions/upload-artifact@v4
        with:
          name: packs_manifest
          path: |
            build/reports/packs_manifest.json
            build/reports/packs_manifest.md

      - name: Run packs manifest test
        run: flutter test -r expanded test/packs_manifest_test.dart

      - name: Run L3 demo tests
        run: flutter test -r expanded test/l3_demo_*

      - name: PackRun L3 (seed 111)
        run: dart run tool/l3/pack_run_cli.dart --dir build/tmp/l3/111 --out build/reports/l3_packrun_111.json

      - name: PackRun L3 aggro (seed 111)
        run: dart run tool/l3/pack_run_cli.dart --dir build/tmp/l3/111 --out build/reports/l3_packrun_aggro.json --weightsPreset aggro

      - name: L3 A/B diff 111
        run: dart run tool/metrics/l3_ab_diff.dart --base build/reports/l3_packrun_111.json --challenger build/reports/l3_packrun_aggro.json --out build/reports/l3_ab_111.md

      - run: |
          echo "::group::L3 A/B diff 111"
          FILE="build/reports/l3_ab_111.md"
          if [ -f "$FILE" ]; then
            cat "$FILE"
          else
            echo "_No A/B diff generated for this run (placeholder to keep CI green)._"
          fi
          echo "::endgroup::"

      - uses: actions/upload-artifact@v4
        with:
          name: l3_ab_111.md
          path: build/reports/l3_ab_111.md

      - name: PackRun L3 (seed 222)
        run: dart run tool/l3/pack_run_cli.dart --dir build/tmp/l3/222 --out build/reports/l3_packrun_222.json

      - name: PackRun L3 (seed 333)
        run: dart run tool/l3/pack_run_cli.dart --dir build/tmp/l3/333 --out build/reports/l3_packrun_333.json

      - name: L3 PackRun metrics
        run: dart run tool/metrics/l3_packrun_report.dart --reports build/reports/l3_packrun_111.json,build/reports/l3_packrun_222.json,build/reports/l3_packrun_333.json --out build/reports/l3_report.md

      - run: |
          echo "::group::L3 Metrics"
          cat build/reports/l3_report.md
          echo "::endgroup::"

      - uses: actions/upload-artifact@v4
        with:
          name: l3_report.md
          path: build/reports/l3_report.md

      - name: Upload L3 PackRun reports
        uses: actions/upload-artifact@v4
        with:
          name: l3_packrun_reports
          path: |
            build/reports/l3_packrun_111.json
            build/reports/l3_packrun_222.json
            build/reports/l3_packrun_333.json

      - name: Run L3 tests
        run: flutter test -r expanded test/l3_*
