import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/targeted_pack_booster_engine.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/yaml_pack_exporter.dart';

class _FakeDecayTracker implements SkillDecayTracker {
  final List<String> tags;
  _FakeDecayTracker(this.tags);
  @override
  Future<List<String>> getDecayedTags({required double threshold}) async => tags;
}

class _FakeMasteryAnalyzer implements TagMasteryAnalyzer {
  final List<String> tags;
  _FakeMasteryAnalyzer(this.tags);
  @override
  Future<List<String>> findWeakTags(double threshold) async => tags;
}

class _CapturingExporter extends YamlPackExporter {
  TrainingPackTemplateV2? last;
  @override
  Future<File> export(TrainingPackTemplateV2 pack) async {
    last = pack;
    final file = File('${Directory.systemTemp.path}/test.yaml');
    await file.writeAsString('');
    return file;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TrainingPackLibraryV2.instance.clear();
  });

  TrainingPackTemplateV2 buildPack(String id, String tag) {
    final spot1 =
        TrainingPackSpot(id: '${id}_s1', tags: [tag], board: ['As', 'Kd', '2c']);
    final spot2 =
        TrainingPackSpot(id: '${id}_s2', tags: [tag], board: ['Ah', 'Ks', '3d']);
    return TrainingPackTemplateV2(
      id: id,
      name: 'Sample $id',
      trainingType: TrainingType.custom,
      spots: [spot1, spot2],
      spotCount: 2,
      tags: [tag],
      gameType: GameType.cash,
    );
  }

  test('detects boost candidates from analytics', () async {
    final pack = buildPack('p1', 'push');
    TrainingPackLibraryV2.instance.addPack(pack);
    SharedPreferences.setMockInitialValues({
      'booster.threshold': 0.8,
      'booster.ratio': 2.0,
    });
    final engine = TargetedPackBoosterEngine(
      decayTracker: _FakeDecayTracker(['push']),
      masteryAnalyzer: _FakeMasteryAnalyzer(['push']),
    );
    final candidates = await engine.detectBoostCandidates();
    expect(candidates.length, 1);
    expect(candidates.first.packId, 'p1');
    expect(candidates.first.ratio, 2.0);
  });

  test('boostPacks exports boosted template', () async {
    final pack = buildPack('p2', 'fold');
    TrainingPackLibraryV2.instance.addPack(pack);
    final exporter = _CapturingExporter();
    final engine = TargetedPackBoosterEngine(exporter: exporter);
    final req =
        PackBoosterRequest(packId: 'p2', tags: ['fold'], ratio: 1.5);
    await engine.boostPacks([req]);
    final boosted = exporter.last;
    expect(boosted, isNotNull);
    expect(boosted!.id, 'p2_boosted');
    expect(boosted.spotCount, greaterThan(pack.spotCount));
    expect(boosted.meta['boostTags'], ['fold']);
  });
}
