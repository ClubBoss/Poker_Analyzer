import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_track_progress_service.dart';
import 'package:poker_analyzer/widgets/skill_tree_track_header_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();

  SkillTreeNodeModel node(String id) =>
      SkillTreeNodeModel(id: id, title: 'Title', category: 'Push/Fold');

  testWidgets('builds header with progress', (WidgetTester tester) async {
    final tree = builder.build([node('a')]).tree;
    final progress = TrackProgressEntry(
      tree: tree,
      completionRate: 0.3,
      isCompleted: false,
    );
    final header = const SkillTreeTrackHeaderBuilder().build(
      root: node('a'),
      progress: progress,
    );
    await tester.pumpWidget(MaterialApp(home: header));

    expect(find.text('Title'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.3, 0.001));
    expect(find.text('30%'), findsOneWidget);
  });

  testWidgets('shows completed status', (WidgetTester tester) async {
    final tree = builder.build([node('b')]).tree;
    final progress = TrackProgressEntry(
      tree: tree,
      completionRate: 1.0,
      isCompleted: true,
    );
    final header = const SkillTreeTrackHeaderBuilder().build(
      root: node('b'),
      progress: progress,
    );
    await tester.pumpWidget(MaterialApp(home: header));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
