import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/unlock_rules.dart';
import 'package:poker_analyzer/services/training_pack_stats_service.dart';
import 'package:poker_analyzer/services/training_path_unlock_service.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

TrainingPackTemplateV2 tpl(String id, {UnlockRules? rules}) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    unlockRules: rules,
    spots: const [],
    spotCount: 0,
  );
}

TrainingPackStat stat({double accuracy = 0, double ev = 0, double icm = 0}) {
  return TrainingPackStat(
    accuracy: accuracy,
    last: DateTime.now(),
    preEvPct: ev,
    preIcmPct: icm,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = TrainingPathUnlockService();

  test('pack without rules is unlocked', () {
    final packs = [tpl('a')];
    final result = service.getUnlocked(packs, {});
    expect(result.map((e) => e.id), ['a']);
  });

  test('locked by accuracy requirement', () {
    final pack = tpl('b', rules: const UnlockRules(minAccuracy: 80));
    final stats = {'b': stat(accuracy: 70)};
    expect(service.getUnlocked([pack], stats), isEmpty);
    stats['b'] = stat(accuracy: 90);
    expect(service.getUnlocked([pack], stats).map((e) => e.id), ['b']);
  });

  test('requires previous pack completed', () {
    final pack = tpl('c', rules: const UnlockRules(requiredPacks: ['a']));
    expect(service.getUnlocked([pack], {}), isEmpty);
    final stats = {'a': stat(accuracy: 100)};
    expect(service.getUnlocked([pack], stats).map((e) => e.id), ['c']);
  });

  test('ev and icm thresholds', () {
    final pack = tpl('d', rules: const UnlockRules(minEV: 0.5, minIcm: 0.4));
    final statsLow = {'d': stat(accuracy: 100, ev: 0.3, icm: 0.5)};
    expect(service.getUnlocked([pack], statsLow), isEmpty);
    final statsOk = {'d': stat(accuracy: 100, ev: 0.6, icm: 0.5)};
    expect(service.getUnlocked([pack], statsOk).map((e) => e.id), ['d']);
  });
}
