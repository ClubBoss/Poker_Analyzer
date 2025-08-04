import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/theory_lesson_tag_sidebar.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

void main() {
  testWidgets('sidebar toggles tag selection', (tester) async {
    const l1 = TheoryMiniLessonNode(
      id: 'l1',
      title: 'A',
      content: '',
      tags: ['icm', 'push'],
    );
    const l2 = TheoryMiniLessonNode(
      id: 'l2',
      title: 'B',
      content: '',
      tags: ['defense', 'icm'],
    );

    Set<String>? selected;
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 200,
        child: TheoryLessonTagSidebar(
          lessons: const [l1, l2],
          onChanged: (s) => selected = s,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('defense (1)'), findsOneWidget);
    expect(find.text('icm (2)'), findsOneWidget);
    expect(find.text('push (1)'), findsOneWidget);

    await tester.tap(find.text('icm (2)'));
    await tester.pumpAndSettle();
    expect(selected, contains('icm'));

    await tester.tap(find.text('Показать всё'));
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
  });
}
