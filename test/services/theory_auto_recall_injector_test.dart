import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_auto_recall_injector.dart';

class _FakeRetention extends DecayTagRetentionTrackerService {
  final bool decayed;
  const _FakeRetention(this.decayed);
  @override
  Future<bool> isDecayed(String tag, {double threshold = 30}) async => decayed;
}

class _FakeLessonLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> lessons;
  _FakeLessonLibrary(this.lessons);

  @override
  List<TheoryMiniLessonNode> get all => lessons;

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  TheoryMiniLessonNode? getById(String id) =>
      lessons.firstWhere((l) => l.id == id, orElse: () => lessons.first);

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [
        for (final l in lessons)
          if (l.tags.any(tags.contains)) l
      ];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());

  @override
  List<String> linkedPacksFor(String lessonId) => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('injects snippet for decayed tag', (tester) async {
    const lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: 'Push fold basics',
      content: 'Always shove with 10 BB from the button.',
      tags: ['push'],
      nextIds: [],
    );
    final spot = TrainingPackSpot(id: 's1', tags: ['push']);
    final injector = TheoryAutoRecallInjector(
      retention: const _FakeRetention(true),
      lessons: _FakeLessonLibrary(const [lesson]),
    );

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => injector.build(context, 'n1', spot),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Push fold basics'), findsOneWidget);
    expect(find.textContaining('Always shove'), findsOneWidget);
  });
}
