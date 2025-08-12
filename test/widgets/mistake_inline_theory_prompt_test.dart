import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/widgets/mistake_inline_theory_prompt.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

class _FakeProvider {
  final List<TheoryMiniLessonNode> lessons;
  _FakeProvider(this.lessons);
  Future<List<TheoryMiniLessonNode>> call(List<String> tags) async => lessons;
}

class _EventLogger {
  final events = <Map<String, dynamic>>[];
  Future<void> call(String event, Map<String, dynamic> params) async {
    events.add({'event': event, ...params});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MistakeInlineTheoryPrompt', () {
    testWidgets('shows and opens single lesson', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final lesson = TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: 'c',
        tags: ['a'],
      );
      final provider = _FakeProvider([lesson]);
      final logger = _EventLogger();

      await tester.pumpWidget(
        MaterialApp(
          home: MistakeInlineTheoryPrompt(
            tags: const ['a'],
            packId: 'p1',
            spotId: 's1',
            matchProvider: provider.call,
            log: logger.call,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learn now (Theory • 1)'), findsOneWidget);
      expect(
        logger.events.any(
          (e) =>
              e['event'] == 'theory_suggested_after_mistake' && e['count'] == 1,
        ),
        isTrue,
      );

      await tester.tap(find.text('Learn now (Theory • 1)'));
      await tester.pumpAndSettle();

      expect(find.text('L1'), findsOneWidget);
      expect(
        logger.events.any((e) => e['event'] == 'theory_link_opened'),
        isTrue,
      );
    });

    testWidgets('shows list when multiple lessons', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final lessons = [
        TheoryMiniLessonNode(id: 'l1', title: 'L1', content: 'c', tags: ['a']),
        TheoryMiniLessonNode(id: 'l2', title: 'L2', content: 'c', tags: ['a']),
      ];
      final provider = _FakeProvider(lessons);
      final logger = _EventLogger();

      await tester.pumpWidget(
        MaterialApp(
          home: MistakeInlineTheoryPrompt(
            tags: const ['a'],
            packId: 'p1',
            spotId: 's1',
            matchProvider: provider.call,
            log: logger.call,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Learn now (Theory • 2)'));
      await tester.pumpAndSettle();

      expect(find.text('L1'), findsOneWidget);
      expect(
        logger.events.any(
          (e) => e['event'] == 'theory_list_opened' && e['count'] == 2,
        ),
        isTrue,
      );

      await tester.tap(find.text('L1'));
      await tester.pumpAndSettle();

      expect(find.text('L1'), findsOneWidget);
      expect(
        logger.events.where((e) => e['event'] == 'theory_link_opened').length,
        1,
      );
    });

    testWidgets('preference disables prompt', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final lesson = TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: 'c',
        tags: ['a'],
      );
      final provider = _FakeProvider([lesson]);
      final logger = _EventLogger();

      await tester.pumpWidget(
        MaterialApp(
          home: MistakeInlineTheoryPrompt(
            tags: const ['a'],
            packId: 'p1',
            spotId: 's1',
            matchProvider: provider.call,
            log: logger.call,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("Don't show for this pack"));
      await tester.pumpAndSettle();

      expect(find.text('Learn now (Theory • 1)'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: MistakeInlineTheoryPrompt(
            tags: const ['a'],
            packId: 'p1',
            spotId: 's1',
            matchProvider: provider.call,
            log: logger.call,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learn now (Theory • 1)'), findsNothing);
    });

    testWidgets('fires onTheoryViewed after closing lesson', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final lesson = TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: 'c',
        tags: ['a'],
      );
      final provider = _FakeProvider([lesson]);
      final logger = _EventLogger();
      final viewed = <List<String?>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: MistakeInlineTheoryPrompt(
            tags: const ['a'],
            packId: 'p1',
            spotId: 's1',
            matchProvider: provider.call,
            log: logger.call,
            onTheoryViewed: (spot, pack, lessonId) {
              viewed.add([spot, pack, lessonId]);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Learn now (Theory • 1)'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(viewed, [
        ['s1', 'p1', 'l1'],
      ]);
    });
  });
}
