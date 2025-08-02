import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/widgets/skill_tree_stage_badge_icon.dart';

void main() {
  testWidgets('renders locked badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SkillTreeStageBadgeIcon(badge: 'locked')),
    );
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('renders in progress badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SkillTreeStageBadgeIcon(badge: 'in_progress')),
    );
    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
  });

  testWidgets('renders perfect badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SkillTreeStageBadgeIcon(badge: 'perfect')),
    );
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });
}
