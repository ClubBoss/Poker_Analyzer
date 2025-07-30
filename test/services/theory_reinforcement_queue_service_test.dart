import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_reinforcement_queue_service.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final Map<String, TheoryMiniLessonNode> items;
  _FakeLibrary(this.items);

  @override
  List<TheoryMiniLessonNode> get all => items.values.toList();

  @override
  TheoryMiniLessonNode? getById(String id) => items[id];

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => const [];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('registerSuccess schedules next interval', () async {
    final service = TheoryReinforcementQueueService.instance;
    await service.registerSuccess('l1');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_reinforcement_queue')!;
    final data = jsonDecode(raw) as Map;
    final entry = data['l1'] as Map<String, dynamic>;
    expect(entry['level'], 1);
  });

  test('registerFailure resets and schedules one day', () async {
    final service = TheoryReinforcementQueueService.instance;
    await service.registerSuccess('l2');
    await service.registerFailure('l2');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_reinforcement_queue')!;
    final data = jsonDecode(raw) as Map;
    final entry = data['l2'] as Map<String, dynamic>;
    expect(entry['level'], 0);
  });

  test('getDueLessons returns sorted nodes', () async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theory_reinforcement_queue',
      jsonEncode({
        'a': {
          'level': 0,
          'next': now.subtract(const Duration(hours: 1)).toIso8601String(),
        },
        'b': {
          'level': 0,
          'next': now.subtract(const Duration(hours: 2)).toIso8601String(),
        },
      }),
    );

    final library = _FakeLibrary({
      'a': const TheoryMiniLessonNode(id: 'a', title: 'A', content: ''),
      'b': const TheoryMiniLessonNode(id: 'b', title: 'B', content: ''),
    });

    final service = TheoryReinforcementQueueService.instance;
    final result = await service.getDueLessons(max: 2, library: library);
    expect(result.map((e) => e.id), ['b', 'a']);
  });
}
