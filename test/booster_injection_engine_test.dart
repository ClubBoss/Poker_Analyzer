import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_injection_engine.dart';
import 'package:poker_analyzer/models/weak_cluster_info.dart';
import 'package:poker_analyzer/models/theory_cluster_summary.dart';
import 'package:poker_analyzer/models/player_profile.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

WeakClusterInfo _cluster(String tag) => WeakClusterInfo(
      cluster: TheoryClusterSummary(
        size: 1,
        entryPointIds: const ['l1'],
        sharedTags: {tag},
      ),
      coverage: 1.0,
      score: 1.0,
    );

TrainingPackTemplateV2 _booster(String id, String tag) =>
    TrainingPackTemplateV2(
      id: id,
      name: id,
      trainingType: TrainingType.theory,
      tags: [tag],
      spots: const [],
      spotCount: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('scheduleBoosters prioritizes repeating tags', () {
    final clusters = [_cluster('a'), _cluster('a'), _cluster('b')];
    final boosters = [_booster('b1', 'a'), _booster('b2', 'b')];
    final profile = PlayerProfile(
      xp: 150,
      tags: {'c'},
      tagAccuracy: {'a': 0.5, 'b': 0.5},
    );

    const engine = BoosterInjectionEngine();
    final result = engine.scheduleBoosters(
      clusters: clusters,
      boosters: boosters,
      profile: profile,
    );

    expect(result.length, 2);
    expect(result.first.id, 'b1');
  });

  test('scheduleBoosters skips mastered tags', () {
    final clusters = [_cluster('a')];
    final boosters = [_booster('b1', 'a')];
    final profile = PlayerProfile(
      xp: 0,
      tags: {'a'},
      tagAccuracy: {'a': 0.9},
    );

    const engine = BoosterInjectionEngine();
    final result = engine.scheduleBoosters(
      clusters: clusters,
      boosters: boosters,
      profile: profile,
    );

    expect(result, isEmpty);
  });
}
