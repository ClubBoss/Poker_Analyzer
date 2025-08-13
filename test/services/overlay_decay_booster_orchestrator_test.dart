import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/overlay_decay_booster_orchestrator.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/inbox_booster_service.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_tag_decay_tracker.dart';

class _FakeDecay extends TheoryTagDecayTracker {
  final Map<String, double> scores;
  _FakeDecay(this.scores);

  @override
  Future<Map<String, double>> computeDecayScores({DateTime? now}) async =>
      scores;
}

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> lessons;
  _FakeLibrary(this.lessons);

  @override
  List<TheoryMiniLessonNode> get all => lessons;

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  TheoryMiniLessonNode? getById(String id) =>
      lessons.firstWhere((e) => e.id == id, orElse: () => null);

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final result = <TheoryMiniLessonNode>[];
    for (final t in tags) {
      result.addAll(lessons.where((e) => e.tags.contains(t)));
    }
    return result;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('findCandidateLesson returns decayed lesson', () async {
    final lessons = [
      const TheoryMiniLessonNode(
          id: 'l1', title: 'A', content: '', tags: ['a']),
      const TheoryMiniLessonNode(
          id: 'l2', title: 'B', content: '', tags: ['b']),
    ];
    final service = OverlayDecayBoosterOrchestrator(
      decay: _FakeDecay({'a': 60, 'b': 20}),
      lessons: _FakeLibrary(lessons),
      progress: MiniLessonProgressTracker.instance,
      inbox: InboxBoosterService(),
    );
    final lesson = await service.findCandidateLesson();
    expect(lesson?.id, 'l1');
  });

  test('recently viewed lesson skipped', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'mini_lesson_progress_l1':
          jsonEncode({'lastViewed': now.toIso8601String()}),
    });
    final lessons = [
      const TheoryMiniLessonNode(
          id: 'l1', title: 'A', content: '', tags: ['a']),
    ];
    final service = OverlayDecayBoosterOrchestrator(
      decay: _FakeDecay({'a': 60}),
      lessons: _FakeLibrary(lessons),
      progress: MiniLessonProgressTracker.instance,
      inbox: InboxBoosterService(),
    );
    final lesson = await service.findCandidateLesson(
        now: now.add(const Duration(days: 1)));
    expect(lesson, isNull);
  });
}
