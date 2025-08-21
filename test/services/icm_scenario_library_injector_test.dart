import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/icm_scenario_library_injector.dart';
import 'package:poker_analyzer/services/pack_novelty_guard_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';

class _FakeGuard extends PackNoveltyGuardService {
  final bool Function(int) duplicateWhen;
  int evaluateCalls = 0;

  _FakeGuard(this.duplicateWhen) : super();

  @override
  Future<PackNoveltyResult> evaluate(TrainingPackTemplateV2 candidate) async {
    evaluateCalls++;
    final dup = duplicateWhen(candidate.spots.length);
    return PackNoveltyResult(
      isDuplicate: dup,
      jaccard: dup ? 1.0 : 0.0,
      overlapCount: dup ? candidate.spots.length : 0,
      topSimilar: const [],
    );
  }

  @override
  Future<void> registerExport(TrainingPackTemplateV2 tpl) async {}
}

ICMScenario _scenario(String id, String stage) {
  return ICMScenario(
    scenarioId: id,
    stage: stage,
    players: 3,
    stacksBB: const [10, 10, 10],
    heroSeat: 0,
    payouts: const [50, 30, 20],
    effectiveBB: 10,
    positions: const ['BTN', 'SB', 'BB'],
    tags: const ['icm', 'mtt', 'finalTable'],
    spot: TrainingPackSpot(id: '${id}_spot', hand: HandData()),
    weight: 1.0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ICMScenarioLibraryInjector', () {
    late List<ICMScenario> library;

    setUp(() {
      library = [
        _scenario('s1', 'FT9'),
        _scenario('s2', 'FT6'),
        _scenario('s3', 'HU'),
      ];
      SharedPreferences.setMockInitialValues({
        'icm.inject.enabled': true,
        'icm.inject.minSpots': 2,
        'icm.inject.ratio': 0.15,
        'icm.inject.maxPerPack': 6,
        'icm.inject.requireTags': ['finalTable'],
      });
    });

    test('injects scenarios respecting policy and metadata', () async {
      final pack = TrainingPackModel(
        id: 'p1',
        title: 'Pack',
        spots: [
          for (var i = 0; i < 10; i++)
            TrainingPackSpot(id: 's$i', hand: HandData()),
        ],
        tags: const ['finalTable'],
        metadata: const {},
      );
      final injector = ICMScenarioLibraryInjector(scenarios: library);
      final result = await injector.inject(pack);
      expect(result.spots.length, 12);
      expect(result.metadata['icmInjected'], isTrue);
      expect(result.metadata['icmScenarioCount'], 2);
      final stages =
          result.spots.take(2).map((s) => s.meta['icm']['stage']).toSet();
      expect(stages.length, 2); // diversity by stage
      expect(result.spots.first.tags.contains('icm'), isTrue);
    });

    test('does nothing when required tags missing', () async {
      SharedPreferences.setMockInitialValues({
        'icm.inject.enabled': true,
        'icm.inject.requireTags': ['mtt'],
      });
      final pack = TrainingPackModel(
        id: 'p1',
        title: 'Pack',
        spots: [TrainingPackSpot(id: 's1', hand: HandData())],
        tags: const ['cash'],
        metadata: const {},
      );
      final injector = ICMScenarioLibraryInjector(scenarios: library);
      final result = await injector.inject(pack);
      expect(result.spots.length, 1);
      expect(result.metadata.containsKey('icmInjected'), isFalse);
    });

    test('selection is deterministic', () async {
      final pack = TrainingPackModel(
        id: 'p42',
        title: 'Pack',
        spots: [
          for (var i = 0; i < 5; i++)
            TrainingPackSpot(id: 's$i', hand: HandData()),
        ],
        tags: const ['finalTable'],
        metadata: const {},
      );
      final injector = ICMScenarioLibraryInjector(scenarios: library);
      final r1 = await injector.inject(pack);
      final r2 = await injector.inject(pack);
      expect(r1.spots.first.id, r2.spots.first.id);
    });

    test(
      'reduces injection count when novelty guard flags duplicate',
      () async {
        final pack = TrainingPackModel(
          id: 'p1',
          title: 'Pack',
          spots: [
            for (var i = 0; i < 10; i++)
              TrainingPackSpot(id: 's$i', hand: HandData()),
          ],
          tags: const ['finalTable'],
          metadata: const {},
        );
        final guard = _FakeGuard(
          (count) => count > 11,
        ); // duplicate if >1 injected
        final injector = ICMScenarioLibraryInjector(
          scenarios: library,
          noveltyGuard: guard,
        );
        final result = await injector.inject(pack);
        expect(result.spots.length, 11);
        expect(result.metadata['icmScenarioCount'], 1);
        expect(guard.evaluateCalls, greaterThan(0));
      },
    );
  });
}
