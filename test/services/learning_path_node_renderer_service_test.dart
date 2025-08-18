import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/learning_path_entry_group_builder.dart';
import 'package:poker_analyzer/services/learning_path_node_analytics_logger.dart';
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
    final group = LearningPathEntryGroup(
      title: 'Review',
      entries: const [lesson],
    );
    final logger = _FakeLogger();
    final service = LearningPathNodeRendererService(analyticsLogger: logger);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => service.build(context, 'n1', [group]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Lesson A'), findsOneWidget);
    expect(logger.logged.length, 1);
    expect(logger.logged.first['nodeId'], 'n1');
    expect(logger.logged.first['title'], 'Review');
  });
}

class _FakeLogger extends LearningPathNodeAnalyticsLogger {
  _FakeLogger();

  final List<Map<String, String>> logged = [];

  @override
  Future<void> logGroupViewed(String nodeId, String title) async {
    logged.add({'nodeId': nodeId, 'title': title});
  }
}
