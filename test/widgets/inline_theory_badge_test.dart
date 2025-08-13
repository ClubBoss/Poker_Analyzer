import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/inline_theory_linker_cache.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/user_action_logger.dart';
import 'package:poker_analyzer/widgets/common/inline_theory_badge.dart';

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
      lessons.firstWhere((l) => l.id == id, orElse: () => null);

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final set = tags.toSet();
    final seen = <String>{};
    final result = <TheoryMiniLessonNode>[];
    for (final l in lessons) {
      if (l.tags.any(set.contains)) {
        if (seen.add(l.id)) result.add(l);
      }
    }
    return result;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());

  @override
  List<String> linkedPacksFor(String lessonId) => const [];
}

void main() {
  testWidgets('shows count and logs telemetry', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await UserActionLogger.instance.load();

    final lessons = const [
      TheoryMiniLessonNode(id: 'l1', title: 'L1', content: '', tags: ['tag']),
      TheoryMiniLessonNode(id: 'l2', title: 'L2', content: '', tags: ['tag']),
    ];
    final cache = InlineTheoryLinkerCache(library: _FakeLibrary(lessons));
    await cache.ensureReady();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InlineTheoryBadge(
          tags: const ['tag'],
          spotId: 's1',
          packId: 'p1',
          cache: cache,
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Theory • 2'), findsOneWidget);

    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();
    expect(find.text('L1'), findsOneWidget);

    final events1 = UserActionLogger.instance.events;
    expect(events1.last['event'], 'theory_list_opened');
    expect(events1.last['pack_id'], 'p1');
    expect(events1.last['spot_id'], 's1');

    await tester.tap(find.text('L1'));
    await tester.pumpAndSettle();

    final events = UserActionLogger.instance.events;
    final last = events.last;
    expect(last['event'], 'theory_link_opened');
    expect(last['pack_id'], 'p1');
    expect(last['spot_id'], 's1');
    expect(last['lesson_id'], 'l1');
  });
}
