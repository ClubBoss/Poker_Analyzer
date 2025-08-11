import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/skill_tag_coverage_guard_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  TrainingPackTemplateV2 packWithTags(
    List<List<String>> tags, {
    String? audience,
  }) {
    final spots = [
      for (var i = 0; i < tags.length; i++)
        TrainingPackSpot(id: 's$i', tags: tags[i]),
    ];
    return TrainingPackTemplateV2(
      id: 'p',
      name: 'P',
      trainingType: TrainingType.quiz,
      spots: spots,
      spotCount: spots.length,
      audience: audience,
    );
  }

  test('rejects pack with zero tags', () async {
    final guard = SkillTagCoverageGuardService(mode: CoverageGuardMode.strict);
    final pack = packWithTags([[]]);
    final report = await guard.evaluate(pack);
    expect(report.coveragePct, 0);
    expect(report.passes, isFalse);
  });

  test('single tag dominance fails coverage pct', () async {
    final guard = SkillTagCoverageGuardService(mode: CoverageGuardMode.strict);
    final pack = packWithTags([
      for (var i = 0; i < 10; i++) ['a'],
    ]);
    final report = await guard.evaluate(pack);
    expect(report.uniqueTags, 1);
    expect(report.passes, isFalse);
  });

  test('audience override applies', () async {
    await SkillTagCoverageGuardService.setThresholds(
      minUniqueTags: 1,
      minCoveragePct: 0.1,
      audience: 'pro',
    );
    final guard = SkillTagCoverageGuardService(mode: CoverageGuardMode.strict);
    final pack = packWithTags([
      for (var i = 0; i < 10; i++) ['a'],
    ], audience: 'pro');
    final report = await guard.evaluate(pack);
    expect(report.passes, isTrue);
  });

  test('fromEnv applies overrides', () async {
    final guard = SkillTagCoverageGuardService.fromEnv({
      'COVERAGE_MODE': 'strict',
      'COVERAGE_MIN_UNIQUE_TAGS': '1',
      'COVERAGE_MIN_PCT': '0.1',
    })!;
    final pack = packWithTags([
      ['a'],
    ]);
    final report = await guard.evaluate(pack);
    expect(guard.mode, CoverageGuardMode.strict);
    expect(report.passes, isTrue);
  });

  test('fromEnv returns null when no vars', () {
    final guard = SkillTagCoverageGuardService.fromEnv({});
    expect(guard, isNull);
  });
}
