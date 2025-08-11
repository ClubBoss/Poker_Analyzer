import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/decay_booster_reminder_service.dart';
import 'package:poker_analyzer/services/inbox_booster_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/theory_tag_decay_tracker.dart';

class _FakeDecay extends TheoryTagDecayTracker {
  final Map<String, double> scores;
  _FakeDecay(this.scores) : super();

  @override
  Future<Map<String, double>> computeDecayScores({DateTime? now}) async => scores;
}

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
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final result = <TheoryMiniLessonNode>[];
    for (final t in tags) {
      result.addAll(items.where((e) => e.tags.contains(t)));
    }
    return result;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => findByTags(tags.toList());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('queues inbox reminder for decayed tag', () async {
    final lessons = [
      const TheoryMiniLessonNode(id: 'l1', title: 'A', content: '', tags: ['a']),
      const TheoryMiniLessonNode(id: 'l2', title: 'B', content: '', tags: ['b']),
    ];
    final service = DecayBoosterReminderService(
      decay: _FakeDecay({'a': 50, 'b': 30}),
      lessons: _FakeLibrary(lessons),
      progress: MiniLessonProgressTracker.instance,
      inbox: InboxBoosterService(),
      rotation: Duration.zero,
    );

    await service.run();

    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('inbox_booster_queue');
    expect(queue, contains('l1'));
  });

  test('recently viewed lesson skipped', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'mini_lesson_progress_l1': jsonEncode({'lastViewed': now.toIso8601String()}),
    });
    final lessons = [
      const TheoryMiniLessonNode(id: 'l1', title: 'A', content: '', tags: ['a']),
    ];
    final service = DecayBoosterReminderService(
      decay: _FakeDecay({'a': 60}),
      lessons: _FakeLibrary(lessons),
      progress: MiniLessonProgressTracker.instance,
      inbox: InboxBoosterService(),
      rotation: Duration.zero,
    );

    await service.run();

    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('inbox_booster_queue') ?? [];
    expect(queue, isEmpty);
  });
}
