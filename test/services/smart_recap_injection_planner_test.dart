import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/smart_recap_injection_planner.dart';
import 'package:poker_analyzer/services/booster_path_history_service.dart';
import 'package:poker_analyzer/services/recap_effectiveness_analyzer.dart';
import 'package:poker_analyzer/services/recap_completion_tracker.dart';
import 'package:poker_analyzer/models/booster_tag_history.dart';

class _FakeHistory extends BoosterPathHistoryService {
  final Map<String, BoosterTagHistory> map;
  _FakeHistory(this.map);
  @override
  Future<Map<String, BoosterTagHistory>> getHistory() async => map;
}

class _FakeAnalyzer extends RecapEffectivenessAnalyzer {
  final Map<String, TagEffectiveness> data;
  _FakeAnalyzer(this.data) : super(tracker: RecapCompletionTracker.instance);
  @override
  Map<String, TagEffectiveness> get stats => data;
  @override
  Future<void> refresh({Duration window = const Duration(days: 14)}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RecapCompletionTracker.instance.resetForTest();
  });

  test('selects most urgent and old tags', () async {
    final hist = _FakeHistory({
      'icm': BoosterTagHistory(
        tag: 'icm',
        shownCount: 0,
        startedCount: 0,
        completedCount: 1,
        lastInteraction: DateTime.now().subtract(const Duration(days: 10)),
      ),
      'push': BoosterTagHistory(
        tag: 'push',
        shownCount: 0,
        startedCount: 0,
        completedCount: 1,
        lastInteraction: DateTime.now().subtract(const Duration(days: 1)),
      ),
    });
    final analyzer = _FakeAnalyzer({
      'icm': const TagEffectiveness(
        tag: 'icm',
        count: 1,
        averageDuration: Duration(seconds: 5),
        repeatRate: 0.1,
      ),
      'push': const TagEffectiveness(
        tag: 'push',
        count: 1,
        averageDuration: Duration(seconds: 5),
        repeatRate: 0.1,
      ),
    });
    final planner =
        SmartRecapInjectionPlanner(history: hist, analyzer: analyzer);
    final plan = await planner.computePlan();
    expect(plan, isNotNull);
    expect(plan!.tagIds.first, 'icm');
  });

  test('excludes recently completed tags', () async {
    final hist = _FakeHistory({
      'icm': BoosterTagHistory(
        tag: 'icm',
        shownCount: 0,
        startedCount: 0,
        completedCount: 1,
        lastInteraction: DateTime.now().subtract(const Duration(days: 1)),
      ),
    });
    final analyzer = _FakeAnalyzer({
      'icm': const TagEffectiveness(
        tag: 'icm',
        count: 1,
        averageDuration: Duration(seconds: 5),
        repeatRate: 0.1,
      ),
    });
    final planner =
        SmartRecapInjectionPlanner(history: hist, analyzer: analyzer);
    final plan = await planner.computePlan();
    expect(plan, isNull);
  });
}
