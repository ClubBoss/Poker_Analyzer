import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/recap_history_tracker.dart';
import 'package:poker_analyzer/services/smart_recap_suggestion_engine.dart';
import 'package:poker_analyzer/services/theory_weakness_repeater.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> items;
  _FakeLibrary(this.items);

  @override
  List<TheoryMiniLessonNode> get all => items;

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  TheoryMiniLessonNode? getById(String id) =>
      items.firstWhere((e) => e.id == id, orElse: () => null);

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [];
}

class _FakeRepeater extends TheoryWeaknessRepeater {
  final List<TheoryMiniLessonNode> lessons;
  const _FakeRepeater(this.lessons);

  @override
  Future<List<TheoryMiniLessonNode>> recommend({int limit = 5, int minDays = 3})
      async => lessons;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RecapHistoryTracker.instance.resetForTest();
  });

  test('returns null when globally fatigued', () async {
    for (var i = 0; i < 2; i++) {
      await RecapHistoryTracker.instance.logRecapEvent('l$i', 't', 'dismissed');
    }
    final engine = SmartRecapSuggestionEngine(
      library: _FakeLibrary([]),
      repeater: const _FakeRepeater([]),
    );
    final result = await engine.getBestRecapCandidate();
    expect(result, isNull);
  });

  test('picks earliest due lesson', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'theory_reinforcement_schedule': jsonEncode({
        'l1': {'level': 0, 'next': now.subtract(const Duration(hours: 2)).toIso8601String()},
        'l2': {'level': 0, 'next': now.subtract(const Duration(hours: 1)).toIso8601String()},
      })
    });
    final lessons = [
      const TheoryMiniLessonNode(id: 'l1', title: 'L1', content: ''),
      const TheoryMiniLessonNode(id: 'l2', title: 'L2', content: ''),
    ];
    final engine = SmartRecapSuggestionEngine(
      library: _FakeLibrary(lessons),
      repeater: const _FakeRepeater([]),
    );
    final result = await engine.getBestRecapCandidate();
    expect(result?.id, 'l1');
  });

  test('falls back to weakness repeater', () async {
    final lesson = const TheoryMiniLessonNode(id: 'w1', title: 'W1', content: '');
    final engine = SmartRecapSuggestionEngine(
      library: _FakeLibrary([lesson]),
      repeater: _FakeRepeater([lesson]),
    );
    final result = await engine.getBestRecapCandidate();
    expect(result?.id, 'w1');
  });
}

