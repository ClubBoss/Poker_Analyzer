import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/widgets/skill_tree_stage_header_badge_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SkillTreeNodeModel node(String id) =>
      SkillTreeNodeModel(id: id, title: id, category: 'cat', level: 1);

  testWidgets('shows lock icon when stage locked', (tester) async {
    final widget = SkillTreeStageHeaderBadgeWidget(
      nodes: [node('a')],
      unlocked: const {},
      completed: const {},
    );
    await tester.pumpWidget(MaterialApp(home: widget));
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  testWidgets('shows hourglass when stage in progress', (tester) async {
    final widget = SkillTreeStageHeaderBadgeWidget(
      nodes: [node('a')],
      unlocked: const {'a'},
      completed: const {},
    );
    await tester.pumpWidget(MaterialApp(home: widget));
    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
  });

  testWidgets('shows check when stage perfect', (tester) async {
    final widget = SkillTreeStageHeaderBadgeWidget(
      nodes: [node('a')],
      unlocked: const {'a'},
      completed: const {'a'},
    );
    await tester.pumpWidget(MaterialApp(home: widget));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
