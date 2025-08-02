import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/skill_tree_stage_badge_icon.dart';
import 'package:poker_analyzer/widgets/skill_tree_stage_badge_legend_widget.dart';

void main() {
  testWidgets('displays legend items', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SkillTreeStageBadgeLegendWidget()),
    );

    expect(find.text('Stage locked'), findsOneWidget);
    expect(find.text('Stage in progress'), findsOneWidget);
    expect(find.text('Perfect completion'), findsOneWidget);
    expect(find.byType(SkillTreeStageBadgeIcon), findsNWidgets(3));
  });
}
