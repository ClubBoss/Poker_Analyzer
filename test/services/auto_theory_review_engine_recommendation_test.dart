import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/auto_theory_review_engine.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/theory_booster_reinjection_policy.dart';
import 'package:poker_analyzer/services/theory_pack_library_service.dart';
import 'package:poker_analyzer/services/smart_booster_summary_engine.dart';
import 'package:poker_analyzer/models/theory_pack_model.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

class _FakeMasteryService extends TagMasteryService {
  final Map<String, double> _map;
  _FakeMasteryService(this._map)
    : super(logs: SessionLogService(sessions: TrainingSessionService()));

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async =>
      _map;
}

class _FakePolicy extends TheoryBoosterReinjectionPolicy {
  final bool allow;
  _FakePolicy(this.allow);
  @override
  Future<bool> shouldReinject(String boosterId) async => allow;
}

class _FakeSummary extends SmartBoosterSummaryEngine {
  final Map<String, double> impact;
  const _FakeSummary(this.impact);
  @override
  Future<BoosterSummary> summarize(String boosterId) async => BoosterSummary(
    id: boosterId,
    avgDeltaEV: impact[boosterId] ?? 0.0,
    totalSpots: 0,
    injections: 1,
  );
}

class _FakeLibrary implements TheoryPackLibraryService {
  final Map<String, TheoryPackModel> packs;
  _FakeLibrary(this.packs);
  @override
  List<TheoryPackModel> get all => packs.values.toList();
  @override
  TheoryPackModel? getById(String id) => packs[id];
  @override
  Future<void> loadAll() async {}
  @override
  Future<void> reload() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getRecommendedBoosters filters and sorts boosters', () async {
    final library = _FakeLibrary({
      'b1': TheoryPackModel(
        id: 'b1',
        title: 'B1',
        sections: const [],
        tags: const ['icm'],
      ),
      'b2': TheoryPackModel(
        id: 'b2',
        title: 'B2',
        sections: const [],
        tags: const ['cbet'],
      ),
    });
    final mastery = _FakeMasteryService({'icm': 0.3, 'cbet': 0.8});
    final policy = _FakePolicy(true);
    const summary = _FakeSummary({'b1': 0.2, 'b2': 0.1});

    final engine = AutoTheoryReviewEngine(
      library: library,
      masteryService: mastery,
      reinjectionPolicy: policy,
      summaryEngine: summary,
    );

    final result = await engine.getRecommendedBoosters(
      recentWeakTags: const ['icm'],
      candidateBoosters: const ['b1', 'b2'],
    );
    expect(result, ['b1']);
  });
}
