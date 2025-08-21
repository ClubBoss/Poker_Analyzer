import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_boost_trigger_service.dart';
import 'package:poker_analyzer/services/recap_completion_tracker.dart';
import 'package:poker_analyzer/services/recap_effectiveness_analyzer.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

class _FakeTracker extends RecapCompletionTracker {
  final Map<String, int> freq;
  _FakeTracker(this.freq);
  @override
  Future<Map<String, int>> tagFrequency({
    Duration window = const Duration(days: 7),
  }) async => freq;
}

class _FakeAnalyzer extends RecapEffectivenessAnalyzer {
  final bool under;
  _FakeAnalyzer(this.under) : super(tracker: RecapCompletionTracker.instance);
  @override
  bool isUnderperforming(
    String tag, {
    int minCompletions = 3,
    Duration minAvgDuration = const Duration(seconds: 5),
    double minRepeatRate = 0.25,
  }) => under;
}

class _FakeLibrary extends MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> lessons;
  _FakeLibrary(this.lessons);
  @override
  Future<void> loadAll() async {}
  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => lessons;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('shouldTriggerBoost returns true when conditions met', () async {
    final tracker = _FakeTracker({'icm': 2});
    final analyzer = _FakeAnalyzer(true);
    final service = TheoryBoostTriggerService(
      tracker: tracker,
      analyzer: analyzer,
    );
    final result = await service.shouldTriggerBoost('icm');
    expect(result, true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_replay_cooldowns');
    expect(raw, isNotNull);
  });

  test('respects cooldown', () async {
    final now = DateTime.now().toIso8601String();
    SharedPreferences.setMockInitialValues({
      'theory_replay_cooldowns': jsonEncode({'boost:icm': now}),
    });
    final tracker = _FakeTracker({'icm': 3});
    final analyzer = _FakeAnalyzer(true);
    final service = TheoryBoostTriggerService(
      tracker: tracker,
      analyzer: analyzer,
    );
    final result = await service.shouldTriggerBoost('icm');
    expect(result, false);
  });

  test('getBoostCandidate returns lesson when trigger passes', () async {
    final tracker = _FakeTracker({'cbet': 2});
    final analyzer = _FakeAnalyzer(true);
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 'A',
      content: '',
      tags: ['cbet'],
    );
    final library = _FakeLibrary([lesson]);
    final service = TheoryBoostTriggerService(
      tracker: tracker,
      analyzer: analyzer,
      library: library,
    );
    final result = await service.getBoostCandidate('cbet');
    expect(result?.id, 'l1');
  });
}
