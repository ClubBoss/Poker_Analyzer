import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_tag_decay_tracker.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/theory_tag_summary_service.dart';

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
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('computeDecayScores factors recency and coverage', () async {
    final now = DateTime(2024, 1, 10);
    SharedPreferences.setMockInitialValues({
      'mini_lesson_progress_l1': jsonEncode({
        'lastViewed': now.subtract(const Duration(days: 1)).toIso8601String(),
      }),
      'mini_lesson_progress_l2': jsonEncode({
        'lastViewed': now.subtract(const Duration(days: 5)).toIso8601String(),
      }),
      'mini_lesson_progress_l3': jsonEncode({
        'lastViewed': now.subtract(const Duration(days: 2)).toIso8601String(),
      }),
    });

    final lessons = [
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'A',
        content: '',
        tags: ['a'],
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'B',
        content: '',
        tags: ['a'],
      ),
      const TheoryMiniLessonNode(
        id: 'l3',
        title: 'C',
        content: '',
        tags: ['b'],
      ),
    ];

    final library = _FakeLibrary(lessons);
    final tracker = TheoryTagDecayTracker(
      library: library,
      progress: MiniLessonProgressTracker.instance,
      summary: TheoryTagSummaryService(library: library),
    );

    final scores = await tracker.computeDecayScores(now: now);
    expect(scores['b']! > scores['a']!, isTrue);
  });
}
