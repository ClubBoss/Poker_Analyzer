import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/learning_path_entry_group_builder.dart';
import 'package:poker_analyzer/services/learning_path_node_renderer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders group headers and entries', (tester) async {
    const lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: 'Lesson A',
      content: '',
      tags: [],
      nextIds: [],
    );
    final group = LearningPathEntryGroup(title: 'Review', entries: const [lesson]);
    final service = LearningPathNodeRendererService();

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => service.build(context, [group]),
      ),
    ));
    await tester.pump();

    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Lesson A'), findsOneWidget);
  });
}
