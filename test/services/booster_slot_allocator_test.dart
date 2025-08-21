import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/booster_slot_allocator.dart';
import 'package:poker_analyzer/services/inbox_booster_tracker_service.dart';
import 'package:poker_analyzer/services/booster_path_history_service.dart';
import 'package:poker_analyzer/services/inbox_booster_tuner_service.dart';
import 'package:poker_analyzer/services/recap_effectiveness_analyzer.dart';
import 'package:poker_analyzer/services/recap_completion_tracker.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

class _FakeTuner extends InboxBoosterTunerService {
  final Map<String, double> scores;
  _FakeTuner(this.scores);
  @override
  Future<Map<String, double>> computeTagBoostScores({
    DateTime? now,
    int recencyDays = 3,
  }) async =>
      scores;
}

class _FakeRecap extends RecapEffectivenessAnalyzer {
  final Map<String, TagEffectiveness> data;
  _FakeRecap(this.data) : super(tracker: RecapCompletionTracker.instance);
  @override
  Map<String, TagEffectiveness> get stats => data;
  @override
  Future<void> refresh({Duration window = const Duration(days: 14)}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InboxBoosterTrackerService.instance.resetForTest();
    RecapCompletionTracker.instance.resetForTest();
  });

  test('assigns goal for new high scoring tag', () async {
    final allocator = BoosterSlotAllocator(
      tuner: _FakeTuner({'icm': 2.0}),
      recap: _FakeRecap({}),
    );
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: '',
      content: '',
      tags: ['icm'],
    );
    final res = await allocator.allocateSlots([lesson]);
    expect(res.single.slot, 'goal');
  });

  test('skips lessons shown recently', () async {
    await InboxBoosterTrackerService.instance.markShown('l1');
    final allocator = BoosterSlotAllocator(
      tuner: _FakeTuner({'icm': 2.0}),
      recap: _FakeRecap({}),
    );
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: '',
      content: '',
      tags: ['icm'],
    );
    final res = await allocator.allocateSlots([lesson]);
    expect(res, isEmpty);
  });

  test('allocates recap slot for urgent tag', () async {
    final recap = _FakeRecap({
      'cbet': TagEffectiveness(
        tag: 'cbet',
        count: 0,
        averageDuration: const Duration(seconds: 1),
        repeatRate: 0.0,
      ),
    });
    final allocator = BoosterSlotAllocator(
      tuner: _FakeTuner({'cbet': 1.0}),
      recap: recap,
    );
    final lesson = const TheoryMiniLessonNode(
      id: 'l2',
      title: '',
      content: '',
      tags: ['cbet'],
    );
    final res = await allocator.allocateSlots([lesson]);
    expect(res.single.slot, 'recap');
  });

  test('defaults to inbox for medium tags', () async {
    await BoosterPathHistoryService.instance.markShown('l3a', 'call');
    await BoosterPathHistoryService.instance.markCompleted('l3a', 'call');

    final recap = _FakeRecap({
      'call': TagEffectiveness(
        tag: 'call',
        count: 3,
        averageDuration: const Duration(seconds: 10),
        repeatRate: 0.7,
      ),
    });
    final allocator = BoosterSlotAllocator(
      tuner: _FakeTuner({'call': 1.0}),
      recap: recap,
    );
    final lesson = const TheoryMiniLessonNode(
      id: 'l3',
      title: '',
      content: '',
      tags: ['call'],
    );
    final res = await allocator.allocateSlots([lesson]);
    expect(res.single.slot, 'inbox');
  });
}
