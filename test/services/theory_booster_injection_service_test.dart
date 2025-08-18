import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/decay_booster_reminder_engine.dart';
import 'package:poker_analyzer/services/theory_booster_injection_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';

class _FakeEngine extends DecayBoosterReminderEngine {
  final String? tag;
  _FakeEngine(this.tag);
  @override
  Future<String?> getTopDecayTag({DateTime? now}) async => tag;
}

class _FakeLibrary implements MiniLessonLibraryService {
  final Map<String, List<TheoryMiniLessonNode>> lessons;
  _FakeLibrary(this.lessons);

  @override
  List<TheoryMiniLessonNode> get all => [for (final l in lessons.values) ...l];

  @override
  TheoryMiniLessonNode? getById(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => null);

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final result = <TheoryMiniLessonNode>[];
    for (final t in tags) {
      result.addAll(lessons[t] ?? const []);
    }
    return result;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns lesson for decayed tag', () async {
    const lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: 'T',
      content: '',
      tags: ['a'],
    );
    final service = TheoryBoosterInjectionService(
      engine: _FakeEngine('a'),
      library: _FakeLibrary({
        'a': [lesson],
      }),
    );
    final result = await service.getLesson();
    expect(result?.id, 'l1');
  });

  test('returns null when no tag', () async {
    final service = TheoryBoosterInjectionService(
      engine: _FakeEngine(null),
      library: _FakeLibrary(const {}),
    );
    final result = await service.getLesson();
    expect(result, isNull);
  });
}
