import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/targeted_pack_booster_engine.dart';
import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/auto_skill_gap_clusterer.dart';
import 'package:poker_analyzer/services/pack_fingerprint_comparer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TrainingPackLibraryV2.instance.clear();
    AutogenStatusDashboardService.instance.clear();
  });

  TrainingPackTemplateV2 buildPack(String id, String tag) {
    final spot1 = TrainingPackSpot(id: '${id}_s1', tags: [tag], board: ['As', 'Kd', '2c']);
    final spot2 = TrainingPackSpot(id: '${id}_s2', tags: [tag], board: ['Ah', 'Ks', '3d']);
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

  test('generates booster with metadata and spot count', () async {
    final pack = buildPack('p1', 'push');
    TrainingPackLibraryV2.instance.addPack(pack);
    final cluster = SkillGapCluster(
      clusterName: 'push',
      tags: ['push'],
      avgAccuracy: 0.5,
      occurrenceCount: 5,
    );
    final engine = TargetedPackBoosterEngine();
    final boosters = await engine.generateBoosters([cluster], spotsPerPack: 1);
    expect(boosters.length, 1);
    final b = boosters.first;
    expect(b.spots.length, 1);
    expect(b.meta['source'], 'booster');
    expect(b.meta['cluster'], 'push');
    expect(b.meta['tags'], ['push']);
  });

  test('skips boosters exceeding novelty threshold', () async {
    final pack = buildPack('p2', 'fold');
    TrainingPackLibraryV2.instance.addPack(pack);
    final cluster = SkillGapCluster(
      clusterName: 'fold',
      tags: ['fold'],
      avgAccuracy: 0.4,
      occurrenceCount: 4,
    );
    final engine = TargetedPackBoosterEngine()
      ..existingFingerprints = [
        PackFingerprint.fromTemplate(pack),
      ];
    final boosters = await engine.generateBoosters([cluster]);
    expect(boosters, isEmpty);
    expect(AutogenStatusDashboardService.instance.boostersSkippedNotifier.value['duplicate'], 1);
  });
}
