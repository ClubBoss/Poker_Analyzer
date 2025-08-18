import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recommends failed lessons after delay', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'mini_lesson_failure_l1': jsonEncode([
        {
          'timestamp': now.subtract(const Duration(days: 5)).toIso8601String(),
          'evLoss': -1.0,
        },
      ]),
      'mini_lesson_failure_l2': jsonEncode([
        {
          'timestamp': now.subtract(const Duration(days: 4)).toIso8601String(),
          'evLoss': -0.2,
        },
      ]),
      'mini_lesson_failure_l3': jsonEncode([
        {
          'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
          'evLoss': -2.0,
        },
      ]),
    });

    final lessons = [
      const TheoryMiniLessonNode(id: 'l1', title: 'L1', content: ''),
      const TheoryMiniLessonNode(id: 'l2', title: 'L2', content: ''),
      const TheoryMiniLessonNode(id: 'l3', title: 'L3', content: ''),
    ];

    final repeater = TheoryWeaknessRepeater(
      library: _FakeLibrary(lessons),
      progress: MiniLessonProgressTracker.instance,
    );

    final result = await repeater.recommend(limit: 2, minDays: 3);
    expect(result.map((e) => e.id).toList(), ['l1', 'l2']);
  });
}
